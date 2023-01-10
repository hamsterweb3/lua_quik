-- Судак-Тудак Универсальный (для акций и фьючерсов). Версия 0.20, 04.06.2020
-- Руслан "Turbo Pascal" (с) 2019.
-- Изменения внёс Александр Элс

-- Если хотите добавить инструменты (а они добавляются в массив aTickerList), не забудьте вписать их данные в массивы
-- * aLotSize - кол-во лотов на сделку. Обычно 1 (помните, что в акциях - кол-во акций в лоте у каждого свой. Так что лучше просто оставьте 1).
-- * aProskalzivanie - для сделки. Примерно пол-процента от цены.
-- * aAccountCode - могут отличаться для фьючерсов и акций.
-- * aClassCode - TQBR для фьючерсов, SPBFUT - для акций.
-- ВНИМАНИЕ! Для каждого инструмента должен быть открытый график с ценой и болосой Боллиинджера.
-- Идентификатор цены: имя тикера + "_Price_Sudak".
-- Идентификатор Боллинджера: имя тикера + "_BB_Sudak".
-- Без прописывания идентификаторов работать не будет.

-- Алгоритм (работает по каждому инструменту из перечисленных в aTickerList).
-- Если Цена снизилась от предыдущей покупки на покупку более чем на StepSize,
-- и при этом мы вошли снизу внутрь Боллинджера, то Докупка aLotSize.
-- Наоборот - сброс aLotSize.
-- aStepSize не играет роли в сильном боковике - мы продаем и покупаем при каждом касании краев Боллинджера.
-- Минимальный диапазон "купи-продай" - aFlatSize.
-- aStepSize нужен только для растягивания усреднения докупки и растягивании усреднения сдачи.
-- Параметры последней следки: направление, цена последней сделки, и объем позиции - хранятся в файликах.
-- Имя Тикера + "_LastPrice" - цена последней сделки.
-- Имя Тикера + "_LastDirection" - направление последней сделки.
-- Имя Тикера + "_Volume" - текущий объем позиции.
-- Робот выставляет сделки по рынку, поэтому в файлик "_LastPrice" может быть записана
-- чуть неточная цена (с учетом проскальзывания).
-- Файлики можно править вручную (хотя нужно ли).
-- Только в лонг. Если условия выполняются, но продавать нечего - не продаем.

-- По расчетам: Если докупать Сбер(ао) с цены 250, то чтобы набрать позу 50 лотов, упав до 150, достаточно капитала в 100т.р.
-- Газпром упадет с 160 до 60 - для удержания достаточно 50т.р.
-- На "рехеджах" (каждая пара бай-селл) еще и заработать можно. Дивы - тоже в нашу пользу.

-- ************************ СЕКЦИЯ ОБЩИХ ПАРАМЕТРОВ ****************************
CLIENT_CODE = "D62154" -- общий код для акций и фьючерсов.
LogFileName = "c:\\SudakTudak\\sudaktudak_log.txt" -- Технический лог.
ParamPath = "c:\\SudakTudak\\" -- здесь хранятся файлики с параметрами. Три файла на каждый инструкмент.
SdelkaLog = "c:\\SudakTudak\\sudaktudak_sdelki.txt" -- Лог сделок. Сюда пишутся ТОЛЬКО сделки.
SleepDuration = 10; -- отдыхаем 10 секунд. Слишком часто не надо молотить.
DemoMode = false -- Включите, чтобы начать "боевые" сделки. Если = false, сделок не будет, просто запишет в лог.

-- ************************ СЕКЦИЯ МАССИВОВ ДЛЯ ИНСТРУМЕНТОВ ************************
aTickerList = {"SBER","GAZP","MTSS", "LKOH", "RSTI", "PHOR"}; -- сюда массив инструментов. Не забывайте перекладывать фьючерсы!!!
-- А при перекладывании фьючерсов не забывайте менять код как здесь, так и в следующих массивах.

-- Следующие массивы должны иметь значения для каждого инструмента из aTickerList
aClassCode = {SBER="TQBR", GAZP="TQBR", MTSS="TQBR", LKOH="TQBR", RSTI="TQBR", PHOR="TQBR"} -- TQBR для акций, SPBFUT для фьючерсов.
aAccountCode = {SBER="L01-00000F00", GAZP="L01-00000F00", MTSS="L01-00000F00", LKOH="L01-00000F00", RSTI="L01-00000F00", PHOR="L01-00000F00"} -- может отличаться для акций и фьючерсов.
aLotSize = {SBER=2,GAZP=2,MTSS=2,LKOH=1,RSTI=5, PHOR=2}; -- Массив лотов для покупки.
aStepSize = {SBER=3,GAZP=2.8,MTSS=5,LKOH=70,RSTI=0.04,PHOR=50}; -- Шаг Цены.
aFlatSize = {SBER=1.2,GAZP=1.4,MTSS=3,LKOH=50,RSTI=0.025,PHOR=30}; -- Шаг Цены.
aProskalzivanie = {SBER=0.02,GAZP=0.02,MTSS=0.1,LKOH=1,RSTI=0.0006,PHOR=2}; -- Проскальзывание при сделке.
aStocksInLot = {SBER=10,GAZP=10,MTSS=10,LKOH=1,RSTI=1000,PHOR=1}; -- Акций на 1 лот для пересчета доходности в рубли.
aCurrentPrice = 0; -- объявление переменной.
aHour_1 = 10; -- Час начала работы
aMinutes_1 = 00; -- Минуты начала работы
aHour_2 = 19; -- Час окончания работы
aComission_prc = 0.2; --комиссия за круг

is_run=true

function main()
	sleep(10000)
	while is_run do
		curr_date=os.date("*t")
		if (curr_date["hour"]>=aHour_1 and curr_date["min"]>aMinutes_1) and curr_date["hour"]<aHour_2 then 
			for k,v in pairs(aTickerList) do			
				Obrabotka(v,k);
			end
		end;
		sleep(SleepDuration*1000) -- Отдыхаем SleepDuration секунд.
	end
end

function GetLastPrice(TickerName, CandleType)
	-- Берем цену из графика. CreateDataSource пока не используем, т.к. при необходимости модификации
	-- алгоритма, хотим легко добавлять индикаторы.
	-- Плюс меньше зависим от коннекта - графики всегда с нами.
	local NL=getNumCandles(TickerName.."_Price_Sudak")
	
	tL, nL, lL = getCandlesByIndex (TickerName.."_Price_Sudak", 0, NL-1, 1) -- last свеча
	if tL ~= nil then
		if tL[0] ~= nil then
			if CandleType=="LOW" then
				aCurrentPrice=tL[0].low -- получили текущую цену (ЦПС)
			elseif CandleType=="OPEN" then
				aCurrentPrice=tL[0].open
			elseif CandleType=="HIGH" then 
				aCurrentPrice=tL[0].high
			else 
				aCurrentPrice=tL[0].close
			end
		end;
	end;
	return aCurrentPrice
end

function GetBollinger(TickerName, LineCode)
	-- получаем текущие значения Боллинлжера.
	-- LineCode может иметь значения: "High", "Middle", "Low"
	local NbbL=getNumCandles(TickerName.."_BB_Sudak")
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 0, NbbL-1, 1)  -- last свеча, средняя линия Боллинджера
	iBB_Local_Middle = tbbL[0].close -- тек значение средней BB Local
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 1, NbbL-1, 1)  -- last свеча, верхняя линия Боллинджера
	iBB_Local_High = tbbL[0].close -- тек значение верхней BB Local
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 2, NbbL-1, 1)  -- last свеча, нижняя линия Боллинджера
	iBB_Local_Low = tbbL[0].close -- тек значение нижней BB Local
	if LineCode == "High" then return iBB_Local_High end
	if LineCode == "Middle" then return iBB_Local_Middle end
	if LineCode == "Low" then return iBB_Local_Low end
end

function PriceCrossMAToUp(TickerName)
	-- Функция возвращает TRUE, если пересекли среднюю линию Боллинджера снизу вверх
	if GetLastPrice(TickerName, "OPEN")<GetBollinger(TickerName, "Middle")
		and GetLastPrice(TickerName, "LAST")>GetBollinger(TickerName, "Middle")
	then return true
	else return false
	end;
end

function PriceCrossMAToDown(TickerName)
	-- Функция возвращает TRUE, если пересекли среднюю линию Боллинджера снизу вверх
	if GetLastPrice(TickerName, "OPEN")>GetBollinger(TickerName, "Middle")
		and GetLastPrice(TickerName, "LAST")<GetBollinger(TickerName, "Middle")
	then return true
	else return false
	end;
end

function PriceEnterToBollingerFromDown(TickerName)
	-- Функция возвращает TRUE, если пересекли нижнюю линию Боллинджера снизу вверх
	-- (то есть вошли внутрь канала Боллинджера снизу).
	if GetLastPrice(TickerName, "LOW")<GetBollinger(TickerName, "Low")
		and GetLastPrice(TickerName, "LAST")>GetBollinger(TickerName, "Low")
	then return true
	else return false
	end;
end

function PriceEnterToBollingerFromUp(TickerName)
	-- Функция возвращает TRUE, если пересекли верхнюю линию Боллинджера сверху вниз
	-- (то есть вошли внутрь канала Боллинджера сверху).
	if GetLastPrice(TickerName, "HIGH")>GetBollinger(TickerName, "High")
		and GetLastPrice(TickerName, "LAST")<GetBollinger(TickerName, "High")
	then return true
	else return false
	end;
end

--Функция Обработки отдельного тикера
function Obrabotka(sTickerName, sNum)
	-- Теперь откываем файлы с нашим тикетом, и читаем оттуда значения: LastPrice, LastDirection, Объем Позы.
	LastPrice = tonumber(GetValueFromFile(ParamPath..sTickerName.."_LastPrice.txt"));
	LastDirection = GetValueFromFile(ParamPath..sTickerName.."_LastDirection.txt");
	iVolume = tonumber(GetValueFromFile(ParamPath..sTickerName.."_Volume.txt"));
	local CurrentPrice=GetLastPrice(sTickerName) -- вытаскиваем из графика текущую цену.
	local profit = tonumber(GetValueFromFile(ParamPath..sTickerName.."_Profit.txt"));
	local comission = LastPrice/100*aComission_prc;
	-- Логируем текущую и последнюю цены и разницу между ними, параметры уровней и накопленную прибыль.
	WLOG(sTickerName.. " Current="..CurrentPrice.. " Last="..LastPrice.." Razn = "..(CurrentPrice-LastPrice).. " StepSize = "..aStepSize[sTickerName].." Vol="..iVolume.." LastDir="..LastDirection.." Profit="..profit.." ("..math.floor(profit*aStocksInLot[sTickerName]).." Р)");
	
	-- Теперь проверяем, не надо ли докупиться?
	if (((CurrentPrice<LastPrice-aStepSize[sTickerName]) or (CurrentPrice<LastPrice-aFlatSize[sTickerName] and LastDirection=="S")) or (iVolume==0)) and PriceEnterToBollingerFromDown(sTickerName) then
		-- Покупаем или Начинаем
		if LastDirection=="S" then
			WLOG("BUY AGAIN");
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit - comission*aLotSize[sTickerName]) -- тут прибыль не считаем, это откуп ранее проданного, но запишем комиссию
		else
			WLOG("BUY NEW LEVEL");
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit - comission*aLotSize[sTickerName])
		end
		if (DoFire(sTickerName, "B", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)+aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "B")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
			LastPrice = CurrentPrice; -- чтобы не продать сразу на следующем условии.
		end
	end
	
	-- Теперь проверяем, не надо ли немного сбросить?
	if ((CurrentPrice>LastPrice+aStepSize[sTickerName]) or (CurrentPrice>LastPrice+aFlatSize[sTickerName] and LastDirection=="B")) and PriceEnterToBollingerFromUp(sTickerName) and (iVolume>0) then
		-- Продаем
		if LastDirection=="B" then
			WLOG("SELL PROFIT "..(CurrentPrice-LastPrice)*aLotSize[sTickerName].."; COMIS "..comission*aLotSize[sTickerName]); 
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + (CurrentPrice-LastPrice)*aLotSize[sTickerName] - comission*aLotSize[sTickerName]); -- Начислили прибыль за продажу ранее купленного
		else
			WLOG("SELL NEW LEVEL PROFIT "..(CurrentPrice-LastPrice)*aLotSize[sTickerName].."; COMIS "..comission*aLotSize[sTickerName]); 
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + (CurrentPrice-LastPrice)*aLotSize[sTickerName] - comission*aLotSize[sTickerName]); -- Начислили примерную прибыль за продажу ранее купленного
		end
		if (DoFire(sTickerName, "S", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)-aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "S")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
		end
	end
end;

function DoFire(SEC_CODE, p_dir, p_price) -- Функция - СДЕЛКА ПО РЫНКУ!
	if p_dir == "B" then AAA = 1 else AAA = -1 end
	t = {
			["CLASSCODE"]=aClassCode[SEC_CODE],
			["SECCODE"]=SEC_CODE,
			["ACTION"]="NEW_ORDER", -- новая сделка.
			["ACCOUNT"]=aAccountCode[SEC_CODE],
			["CLIENT_CODE"]=CLIENT_CODE,
			["TYPE"]="L", -- "M" "L". По M давал ошибку на TQBR.
			["OPERATION"]=p_dir, -- направление сделки, "B" или "S"
			["QUANTITY"]=tostring(aLotSize[SEC_CODE]), -- объем, (акции - в лотах, а не штуках).
			["PRICE"]=tostring(p_price+(aProskalzivanie[SEC_CODE]*AAA)), -- цену лимитки ставим для мгновенного исполнения.
			["TRANS_ID"]="1"
		}
	
	if DemoMode==false then -- Если всё по серьезному, то ...
		res1 = sendTransaction(t) -- ... передаем сделку по рынку.
	end
	
	if (res1~="") then -- Ошибочка вышла. Логируем ошибку.
		WLOG("SendTransaction Error = "..res1);
	end
	
	local l_file1=io.open(SdelkaLog, "a")
	l_file1:write(os.date()..";SECCODE="..SEC_CODE..";PRICE="..p_price..";DIR="..p_dir.."\n")
	l_file1:close()
		
	return res1
end

function GetValueFromFile(FileName) -- Читаем параметр из файла.
	local f = io.open(FileName, "r");
	if f == nil then -- если файла нет, но создаем пустой.
		f = io.open(FileName,"w");
		DefaultValueForFile = "0" -- по умолчанию пишем нуль.
		-- Для LastDirection надо бы писать не нуль, а "B", но пусть будет нуль, т.к.
		-- этого условия достаточно для открытия начальной сделки.
		f:write(DefaultValueForFile)
		f:close();
		-- Открывает уже гарантированно существующий файл в режиме "чтения/записи"
		f = io.open(FileName, "r");
	end;
	aValue = f:read("*l")
	f:close()
	return aValue
end

function SetValueToFile(FileName, aValue) -- Пишем параметр в файл.
	local ff=io.open(FileName, "w") -- используем "w", а не "a", чтобы перезаписать существующий.
	ff:write(aValue)
	ff:close()
end

function OnStop(stop_flag)
	is_run=false
end

function WLOG(st) -- Универсальная функция записи в лог.
	local l_file=io.open(LogFileName, "a") -- используем "a", чтобы добавить новую строку.
	l_file:write(os.date().." "..st.."\n")
	l_file:close()
end