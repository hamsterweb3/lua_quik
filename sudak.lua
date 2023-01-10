-- �����-����� ������������� (��� ����� � ���������). ������ 0.20, 04.06.2020
-- ������ "Turbo Pascal" (�) 2019.
-- ��������� ��� ��������� ���

-- ���� ������ �������� ����������� (� ��� ����������� � ������ aTickerList), �� �������� ������� �� ������ � �������
-- * aLotSize - ���-�� ����� �� ������. ������ 1 (�������, ��� � ������ - ���-�� ����� � ���� � ������� ����. ��� ��� ����� ������ �������� 1).
-- * aProskalzivanie - ��� ������. �������� ���-�������� �� ����.
-- * aAccountCode - ����� ���������� ��� ��������� � �����.
-- * aClassCode - TQBR ��� ���������, SPBFUT - ��� �����.
-- ��������! ��� ������� ����������� ������ ���� �������� ������ � ����� � ������� ������������.
-- ������������� ����: ��� ������ + "_Price_Sudak".
-- ������������� �����������: ��� ������ + "_BB_Sudak".
-- ��� ������������ ��������������� �������� �� �����.

-- �������� (�������� �� ������� ����������� �� ������������� � aTickerList).
-- ���� ���� ��������� �� ���������� ������� �� ������� ����� ��� �� StepSize,
-- � ��� ���� �� ����� ����� ������ �����������, �� ������� aLotSize.
-- �������� - ����� aLotSize.
-- aStepSize �� ������ ���� � ������� �������� - �� ������� � �������� ��� ������ ������� ����� �����������.
-- ����������� �������� "����-������" - aFlatSize.
-- aStepSize ����� ������ ��� ������������ ���������� ������� � ������������ ���������� �����.
-- ��������� ��������� ������: �����������, ���� ��������� ������, � ����� ������� - �������� � ��������.
-- ��� ������ + "_LastPrice" - ���� ��������� ������.
-- ��� ������ + "_LastDirection" - ����������� ��������� ������.
-- ��� ������ + "_Volume" - ������� ����� �������.
-- ����� ���������� ������ �� �����, ������� � ������ "_LastPrice" ����� ���� ��������
-- ���� �������� ���� (� ������ ���������������).
-- ������� ����� ������� ������� (���� ����� ��).
-- ������ � ����. ���� ������� �����������, �� ��������� ������ - �� �������.

-- �� ��������: ���� �������� ����(��) � ���� 250, �� ����� ������� ���� 50 �����, ���� �� 150, ���������� �������� � 100�.�.
-- ������� ������ � 160 �� 60 - ��� ��������� ���������� 50�.�.
-- �� "��������" (������ ���� ���-����) ��� � ���������� �����. ���� - ���� � ���� ������.

-- ************************ ������ ����� ���������� ****************************
CLIENT_CODE = "D62154" -- ����� ��� ��� ����� � ���������.
LogFileName = "c:\\SudakTudak\\sudaktudak_log.txt" -- ����������� ���.
ParamPath = "c:\\SudakTudak\\" -- ����� �������� ������� � �����������. ��� ����� �� ������ �����������.
SdelkaLog = "c:\\SudakTudak\\sudaktudak_sdelki.txt" -- ��� ������. ���� ������� ������ ������.
SleepDuration = 10; -- �������� 10 ������. ������� ����� �� ���� ��������.
DemoMode = false -- ��������, ����� ������ "������" ������. ���� = false, ������ �� �����, ������ ������� � ���.

-- ************************ ������ �������� ��� ������������ ************************
aTickerList = {"SBER","GAZP","MTSS", "LKOH", "RSTI", "PHOR"}; -- ���� ������ ������������. �� ��������� ������������� ��������!!!
-- � ��� �������������� ��������� �� ��������� ������ ��� ��� �����, ��� � � ��������� ��������.

-- ��������� ������� ������ ����� �������� ��� ������� ����������� �� aTickerList
aClassCode = {SBER="TQBR", GAZP="TQBR", MTSS="TQBR", LKOH="TQBR", RSTI="TQBR", PHOR="TQBR"} -- TQBR ��� �����, SPBFUT ��� ���������.
aAccountCode = {SBER="L01-00000F00", GAZP="L01-00000F00", MTSS="L01-00000F00", LKOH="L01-00000F00", RSTI="L01-00000F00", PHOR="L01-00000F00"} -- ����� ���������� ��� ����� � ���������.
aLotSize = {SBER=2,GAZP=2,MTSS=2,LKOH=1,RSTI=5, PHOR=2}; -- ������ ����� ��� �������.
aStepSize = {SBER=3,GAZP=2.8,MTSS=5,LKOH=70,RSTI=0.04,PHOR=50}; -- ��� ����.
aFlatSize = {SBER=1.2,GAZP=1.4,MTSS=3,LKOH=50,RSTI=0.025,PHOR=30}; -- ��� ����.
aProskalzivanie = {SBER=0.02,GAZP=0.02,MTSS=0.1,LKOH=1,RSTI=0.0006,PHOR=2}; -- ��������������� ��� ������.
aStocksInLot = {SBER=10,GAZP=10,MTSS=10,LKOH=1,RSTI=1000,PHOR=1}; -- ����� �� 1 ��� ��� ��������� ���������� � �����.
aCurrentPrice = 0; -- ���������� ����������.
aHour_1 = 10; -- ��� ������ ������
aMinutes_1 = 00; -- ������ ������ ������
aHour_2 = 19; -- ��� ��������� ������
aComission_prc = 0.2; --�������� �� ����

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
		sleep(SleepDuration*1000) -- �������� SleepDuration ������.
	end
end

function GetLastPrice(TickerName, CandleType)
	-- ����� ���� �� �������. CreateDataSource ���� �� ����������, �.�. ��� ������������� �����������
	-- ���������, ����� ����� ��������� ����������.
	-- ���� ������ ������� �� �������� - ������� ������ � ����.
	local NL=getNumCandles(TickerName.."_Price_Sudak")
	
	tL, nL, lL = getCandlesByIndex (TickerName.."_Price_Sudak", 0, NL-1, 1) -- last �����
	if tL ~= nil then
		if tL[0] ~= nil then
			if CandleType=="LOW" then
				aCurrentPrice=tL[0].low -- �������� ������� ���� (���)
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
	-- �������� ������� �������� �����������.
	-- LineCode ����� ����� ��������: "High", "Middle", "Low"
	local NbbL=getNumCandles(TickerName.."_BB_Sudak")
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 0, NbbL-1, 1)  -- last �����, ������� ����� �����������
	iBB_Local_Middle = tbbL[0].close -- ��� �������� ������� BB Local
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 1, NbbL-1, 1)  -- last �����, ������� ����� �����������
	iBB_Local_High = tbbL[0].close -- ��� �������� ������� BB Local
	tbbL, nbbL, lbbL = getCandlesByIndex (TickerName.."_BB_Sudak", 2, NbbL-1, 1)  -- last �����, ������ ����� �����������
	iBB_Local_Low = tbbL[0].close -- ��� �������� ������ BB Local
	if LineCode == "High" then return iBB_Local_High end
	if LineCode == "Middle" then return iBB_Local_Middle end
	if LineCode == "Low" then return iBB_Local_Low end
end

function PriceCrossMAToUp(TickerName)
	-- ������� ���������� TRUE, ���� ��������� ������� ����� ����������� ����� �����
	if GetLastPrice(TickerName, "OPEN")<GetBollinger(TickerName, "Middle")
		and GetLastPrice(TickerName, "LAST")>GetBollinger(TickerName, "Middle")
	then return true
	else return false
	end;
end

function PriceCrossMAToDown(TickerName)
	-- ������� ���������� TRUE, ���� ��������� ������� ����� ����������� ����� �����
	if GetLastPrice(TickerName, "OPEN")>GetBollinger(TickerName, "Middle")
		and GetLastPrice(TickerName, "LAST")<GetBollinger(TickerName, "Middle")
	then return true
	else return false
	end;
end

function PriceEnterToBollingerFromDown(TickerName)
	-- ������� ���������� TRUE, ���� ��������� ������ ����� ����������� ����� �����
	-- (�� ���� ����� ������ ������ ����������� �����).
	if GetLastPrice(TickerName, "LOW")<GetBollinger(TickerName, "Low")
		and GetLastPrice(TickerName, "LAST")>GetBollinger(TickerName, "Low")
	then return true
	else return false
	end;
end

function PriceEnterToBollingerFromUp(TickerName)
	-- ������� ���������� TRUE, ���� ��������� ������� ����� ����������� ������ ����
	-- (�� ���� ����� ������ ������ ����������� ������).
	if GetLastPrice(TickerName, "HIGH")>GetBollinger(TickerName, "High")
		and GetLastPrice(TickerName, "LAST")<GetBollinger(TickerName, "High")
	then return true
	else return false
	end;
end

--������� ��������� ���������� ������
function Obrabotka(sTickerName, sNum)
	-- ������ �������� ����� � ����� �������, � ������ ������ ��������: LastPrice, LastDirection, ����� ����.
	LastPrice = tonumber(GetValueFromFile(ParamPath..sTickerName.."_LastPrice.txt"));
	LastDirection = GetValueFromFile(ParamPath..sTickerName.."_LastDirection.txt");
	iVolume = tonumber(GetValueFromFile(ParamPath..sTickerName.."_Volume.txt"));
	local CurrentPrice=GetLastPrice(sTickerName) -- ����������� �� ������� ������� ����.
	local profit = tonumber(GetValueFromFile(ParamPath..sTickerName.."_Profit.txt"));
	local comission = LastPrice/100*aComission_prc;
	-- �������� ������� � ��������� ���� � ������� ����� ����, ��������� ������� � ����������� �������.
	WLOG(sTickerName.. " Current="..CurrentPrice.. " Last="..LastPrice.." Razn = "..(CurrentPrice-LastPrice).. " StepSize = "..aStepSize[sTickerName].." Vol="..iVolume.." LastDir="..LastDirection.." Profit="..profit.." ("..math.floor(profit*aStocksInLot[sTickerName]).." �)");
	
	-- ������ ���������, �� ���� �� ����������?
	if (((CurrentPrice<LastPrice-aStepSize[sTickerName]) or (CurrentPrice<LastPrice-aFlatSize[sTickerName] and LastDirection=="S")) or (iVolume==0)) and PriceEnterToBollingerFromDown(sTickerName) then
		-- �������� ��� ��������
		if LastDirection=="S" then
			WLOG("BUY AGAIN");
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit - comission*aLotSize[sTickerName]) -- ��� ������� �� �������, ��� ����� ����� ����������, �� ������� ��������
		else
			WLOG("BUY NEW LEVEL");
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit - comission*aLotSize[sTickerName])
		end
		if (DoFire(sTickerName, "B", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)+aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "B")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
			LastPrice = CurrentPrice; -- ����� �� ������� ����� �� ��������� �������.
		end
	end
	
	-- ������ ���������, �� ���� �� ������� ��������?
	if ((CurrentPrice>LastPrice+aStepSize[sTickerName]) or (CurrentPrice>LastPrice+aFlatSize[sTickerName] and LastDirection=="B")) and PriceEnterToBollingerFromUp(sTickerName) and (iVolume>0) then
		-- �������
		if LastDirection=="B" then
			WLOG("SELL PROFIT "..(CurrentPrice-LastPrice)*aLotSize[sTickerName].."; COMIS "..comission*aLotSize[sTickerName]); 
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + (CurrentPrice-LastPrice)*aLotSize[sTickerName] - comission*aLotSize[sTickerName]); -- ��������� ������� �� ������� ����� ����������
		else
			WLOG("SELL NEW LEVEL PROFIT "..(CurrentPrice-LastPrice)*aLotSize[sTickerName].."; COMIS "..comission*aLotSize[sTickerName]); 
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + (CurrentPrice-LastPrice)*aLotSize[sTickerName] - comission*aLotSize[sTickerName]); -- ��������� ��������� ������� �� ������� ����� ����������
		end
		if (DoFire(sTickerName, "S", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)-aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "S")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
		end
	end
end;

function DoFire(SEC_CODE, p_dir, p_price) -- ������� - ������ �� �����!
	if p_dir == "B" then AAA = 1 else AAA = -1 end
	t = {
			["CLASSCODE"]=aClassCode[SEC_CODE],
			["SECCODE"]=SEC_CODE,
			["ACTION"]="NEW_ORDER", -- ����� ������.
			["ACCOUNT"]=aAccountCode[SEC_CODE],
			["CLIENT_CODE"]=CLIENT_CODE,
			["TYPE"]="L", -- "M" "L". �� M ����� ������ �� TQBR.
			["OPERATION"]=p_dir, -- ����������� ������, "B" ��� "S"
			["QUANTITY"]=tostring(aLotSize[SEC_CODE]), -- �����, (����� - � �����, � �� ������).
			["PRICE"]=tostring(p_price+(aProskalzivanie[SEC_CODE]*AAA)), -- ���� ������� ������ ��� ����������� ����������.
			["TRANS_ID"]="1"
		}
	
	if DemoMode==false then -- ���� �� �� ����������, �� ...
		res1 = sendTransaction(t) -- ... �������� ������ �� �����.
	end
	
	if (res1~="") then -- �������� �����. �������� ������.
		WLOG("SendTransaction Error = "..res1);
	end
	
	local l_file1=io.open(SdelkaLog, "a")
	l_file1:write(os.date()..";SECCODE="..SEC_CODE..";PRICE="..p_price..";DIR="..p_dir.."\n")
	l_file1:close()
		
	return res1
end

function GetValueFromFile(FileName) -- ������ �������� �� �����.
	local f = io.open(FileName, "r");
	if f == nil then -- ���� ����� ���, �� ������� ������.
		f = io.open(FileName,"w");
		DefaultValueForFile = "0" -- �� ��������� ����� ����.
		-- ��� LastDirection ���� �� ������ �� ����, � "B", �� ����� ����� ����, �.�.
		-- ����� ������� ���������� ��� �������� ��������� ������.
		f:write(DefaultValueForFile)
		f:close();
		-- ��������� ��� �������������� ������������ ���� � ������ "������/������"
		f = io.open(FileName, "r");
	end;
	aValue = f:read("*l")
	f:close()
	return aValue
end

function SetValueToFile(FileName, aValue) -- ����� �������� � ����.
	local ff=io.open(FileName, "w") -- ���������� "w", � �� "a", ����� ������������ ������������.
	ff:write(aValue)
	ff:close()
end

function OnStop(stop_flag)
	is_run=false
end

function WLOG(st) -- ������������� ������� ������ � ���.
	local l_file=io.open(LogFileName, "a") -- ���������� "a", ����� �������� ����� ������.
	l_file:write(os.date().." "..st.."\n")
	l_file:close()
end