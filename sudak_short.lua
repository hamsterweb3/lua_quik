-- Судак-Тудак Универсальный (для акций и фьючерсов). Версия 0.20, 4.06.2019
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
-- Если Цена снизилась от предыдущей покупки на покупку более чем на ширину Боллинжера,
-- и при этом мы вошли снизу внутрь Боллинджера, то Докупка aLotSize.
-- Наоборот - сброс aLotSize.
-- Минимальный диапазон "купи-продай" определяется функцией автоматом - FiboSize.
-- fiboStepSize нужен только для растягивания усреднения докупки и растягивании усреднения сдачи.
-- Параметры последней следки: направление, цена последней сделки, и объем позиции - хранятся в файликах.
-- Имя Тикера + "_LastPrice" - цена последней сделки.
-- Имя Тикера + "_LastDirection" - направление последней сделки.
-- Имя Тикера + "_Volume" - текущий объем позиции.
-- Имя Тикера + ")Profit" - текущий накопленный объем прибыли в пунктах между закрытыми операциями.
-- Робот выставляет сделки по рынку, поэтому в файлик "_LastPrice" может быть записана
-- чуть неточная цена (с учетом проскальзывания).
-- Файлики можно править вручную (хотя нужно ли).
-- Только в шорт. Если условия выполняются, но покупать нечего - не продаем.

-- ************************ СЕКЦИЯ ОБЩИХ ПАРАМЕТРОВ ****************************
CLIENT_CODE = "7666rwa" -- общий код для акций и фьючерсов.
LogFileName = "c:\\SudakTudak\\short_evgen\\sudaktudak_log.txt" -- Технический лог.
ParamPath = "c:\\SudakTudak\\short_evgen\\" -- здесь хранятся файлики с параметрами. Три файла на каждый инструкмент.
SdelkaLog = "c:\\SudakTudak\\short_evgen\\sudaktudak_sdelki.txt" -- Лог сделок. Сюда пишутся ТОЛЬКО сделки.
SleepDuration = 20; -- отдыхаем 10 секунд. Слишком часто не надо молотить.
DemoMode = false; -- Включите, чтобы начать "боевые" сделки. Если = true, сделок не будет, просто запишет в лог.

-- ************************ СЕКЦИЯ МАССИВОВ ДЛЯ ИНСТРУМЕНТОВ ************************
aTickerList = {"MMU0"}; -- сюда массив инструментов. Не забывайте перекладывать фьючерсы!!!
-- А при перекладывании фьючерсов не забывайте менять код как здесь, так и в следующих массивах.

-- Следующие массивы должны иметь значения для каждого инструмента из aTickerList
aClassCode = {MMU0="SPBFUT"}; -- TQBR для акций, SPBFUT для фьючерсов.
aAccountCode = {MMU0="7666rwa"}; -- может отличаться для акций и фьючерсов.
aLotSize = {MMU0=1}; -- Массив лотов для покупки.
aProskalzivanie = {MMU0=0.05}; -- Проскальзывание при сделке.
maxVolume = -7; -- Сколько всего можем набрать
aCurrentPrice = 0; -- Обнуление
aHour_1 = 10; -- Час начала работы
aHour_2 = 23; -- Час конца работы
aMinutes_1 = 01; -- Минуты начала работы
fibo = 0.1; -- Множитель увеличения каждого уровня усреднения 0.1 = 10% к предыдущему размеру по формуле в FiboLevels
fiboStepSize = {MMU0=20}; -- Размер уровня для усреднения по каждому инструменту
full_flat_size = false; -- false - торговля между средней и крайней линией ББ, true - между крайними линиями
aStartPrice = {MMU0=2800}; -- Минимальная цена, с которой начинается набор позиции, если 0.

is_run=true

function main()
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
	-- Логируем текущую и последнюю цены и разницу между ними.
	WLOG(sTickerName.. " Current="..CurrentPrice.. " Last="..LastPrice.." Razn = "..((CurrentPrice-LastPrice) - (CurrentPrice-LastPrice)%aProskalzivanie[sTickerName]).. " FlatBBSize = "..FiboSize(sTickerName).." Vol="..iVolume.." LastDir="..LastDirection.." FiboStepSize = "..FiboLevels(sTickerName).." Profit="..profit);
  
	-- Теперь проверяем, не надо ли докупиться или скинуть шорт
	if (((CurrentPrice<LastPrice-FiboSize(sTickerName) and LastDirection=="S") or (CurrentPrice<LastPrice-FiboLevels(sTickerName))) and iVolume<0) and PriceEnterToBollingerFromDown(sTickerName) then
		-- Покупаем или Начинаем
		if LastDirection=="S" then
			WLOG("BUY PROFIT "..(LastPrice-CurrentPrice));
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + LastPrice-CurrentPrice) -- начислили прибыль и записали.
		else
			WLOG("BUY NEW LEVEL PROFIT "..(LastPrice-CurrentPrice));
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + LastPrice-CurrentPrice) -- начислили прибыль и записали.
		end
		if (DoFire(sTickerName, "B", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)+aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "B")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
			LastPrice = CurrentPrice; -- чтобы не продать сразу на следующем условии.
		end
	end
	
	-- Теперь проверяем, не надо ли еще продать? Если поза нуль, то набираем в шорт
	if (( (CurrentPrice>LastPrice+FiboLevels(sTickerName) and iVolume>maxVolume) or (CurrentPrice>LastPrice+FiboSize(sTickerName) and LastDirection=="B" and iVolume>maxVolume) ) or (iVolume==0 and CurrentPrice>aStartPrice[sTickerName])) and PriceEnterToBollingerFromUp(sTickerName) then
		-- Продаем
		if LastDirection=="B" then
			WLOG("SELL AGAIN");
		else
			WLOG("SELL NEW LEVEL");
		end
		if (DoFire(sTickerName, "S", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)-aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "S")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
		end
	end
end;

function FiboLevels (sTickerName) -- Функция увеличения размера уровня в зависимости от позиции по тикеру
  local Volume = math.abs(tonumber(iVolume / aLotSize[sTickerName])); 
  local iniStepSize = fiboStepSize[sTickerName];
  local newStepSize = iniStepSize + (iniStepSize * fibo)^Volume;
  return newStepSize;
end;  

function FiboSize (sTickerName) -- Функция определение ширины между линиями Боллинжера
 local CurrentPrice=GetLastPrice(sTickerName, "OPEN") -- вытаскиваем из графика текущую цену.
 local Size=0

	if full_flat_size then		
		Size = math.floor (GetBollinger(sTickerName, "High") - GetBollinger(sTickerName, "Low"))
		return Size
	end
	
	if CurrentPrice >= GetBollinger(sTickerName, "Middle") and full_flat_size==false then
		Size = math.floor (GetBollinger(sTickerName, "High") - GetBollinger(sTickerName, "Middle"))
		return Size
	else
		Size = math.floor (GetBollinger(sTickerName, "Middle") - GetBollinger(sTickerName, "Low"))
		return Size
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