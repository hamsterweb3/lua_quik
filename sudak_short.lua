-- �����-����� ������������� (��� ����� � ���������). ������ 0.20, 4.06.2019
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
-- ���� ���� ��������� �� ���������� ������� �� ������� ����� ��� �� ������ ����������,
-- � ��� ���� �� ����� ����� ������ �����������, �� ������� aLotSize.
-- �������� - ����� aLotSize.
-- ����������� �������� "����-������" ������������ �������� ��������� - FiboSize.
-- fiboStepSize ����� ������ ��� ������������ ���������� ������� � ������������ ���������� �����.
-- ��������� ��������� ������: �����������, ���� ��������� ������, � ����� ������� - �������� � ��������.
-- ��� ������ + "_LastPrice" - ���� ��������� ������.
-- ��� ������ + "_LastDirection" - ����������� ��������� ������.
-- ��� ������ + "_Volume" - ������� ����� �������.
-- ��� ������ + ")Profit" - ������� ����������� ����� ������� � ������� ����� ��������� ����������.
-- ����� ���������� ������ �� �����, ������� � ������ "_LastPrice" ����� ���� ��������
-- ���� �������� ���� (� ������ ���������������).
-- ������� ����� ������� ������� (���� ����� ��).
-- ������ � ����. ���� ������� �����������, �� �������� ������ - �� �������.

-- ************************ ������ ����� ���������� ****************************
CLIENT_CODE = "7666rwa" -- ����� ��� ��� ����� � ���������.
LogFileName = "c:\\SudakTudak\\short_evgen\\sudaktudak_log.txt" -- ����������� ���.
ParamPath = "c:\\SudakTudak\\short_evgen\\" -- ����� �������� ������� � �����������. ��� ����� �� ������ �����������.
SdelkaLog = "c:\\SudakTudak\\short_evgen\\sudaktudak_sdelki.txt" -- ��� ������. ���� ������� ������ ������.
SleepDuration = 20; -- �������� 10 ������. ������� ����� �� ���� ��������.
DemoMode = false; -- ��������, ����� ������ "������" ������. ���� = true, ������ �� �����, ������ ������� � ���.

-- ************************ ������ �������� ��� ������������ ************************
aTickerList = {"MMU0"}; -- ���� ������ ������������. �� ��������� ������������� ��������!!!
-- � ��� �������������� ��������� �� ��������� ������ ��� ��� �����, ��� � � ��������� ��������.

-- ��������� ������� ������ ����� �������� ��� ������� ����������� �� aTickerList
aClassCode = {MMU0="SPBFUT"}; -- TQBR ��� �����, SPBFUT ��� ���������.
aAccountCode = {MMU0="7666rwa"}; -- ����� ���������� ��� ����� � ���������.
aLotSize = {MMU0=1}; -- ������ ����� ��� �������.
aProskalzivanie = {MMU0=0.05}; -- ��������������� ��� ������.
maxVolume = -7; -- ������� ����� ����� �������
aCurrentPrice = 0; -- ���������
aHour_1 = 10; -- ��� ������ ������
aHour_2 = 23; -- ��� ����� ������
aMinutes_1 = 01; -- ������ ������ ������
fibo = 0.1; -- ��������� ���������� ������� ������ ���������� 0.1 = 10% � ����������� ������� �� ������� � FiboLevels
fiboStepSize = {MMU0=20}; -- ������ ������ ��� ���������� �� ������� �����������
full_flat_size = false; -- false - �������� ����� ������� � ������� ������ ��, true - ����� �������� �������
aStartPrice = {MMU0=2800}; -- ����������� ����, � ������� ���������� ����� �������, ���� 0.

is_run=true

function main()
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
	-- �������� ������� � ��������� ���� � ������� ����� ����.
	WLOG(sTickerName.. " Current="..CurrentPrice.. " Last="..LastPrice.." Razn = "..((CurrentPrice-LastPrice) - (CurrentPrice-LastPrice)%aProskalzivanie[sTickerName]).. " FlatBBSize = "..FiboSize(sTickerName).." Vol="..iVolume.." LastDir="..LastDirection.." FiboStepSize = "..FiboLevels(sTickerName).." Profit="..profit);
  
	-- ������ ���������, �� ���� �� ���������� ��� ������� ����
	if (((CurrentPrice<LastPrice-FiboSize(sTickerName) and LastDirection=="S") or (CurrentPrice<LastPrice-FiboLevels(sTickerName))) and iVolume<0) and PriceEnterToBollingerFromDown(sTickerName) then
		-- �������� ��� ��������
		if LastDirection=="S" then
			WLOG("BUY PROFIT "..(LastPrice-CurrentPrice));
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + LastPrice-CurrentPrice) -- ��������� ������� � ��������.
		else
			WLOG("BUY NEW LEVEL PROFIT "..(LastPrice-CurrentPrice));
			SetValueToFile(ParamPath..sTickerName.."_Profit.txt", profit + LastPrice-CurrentPrice) -- ��������� ������� � ��������.
		end
		if (DoFire(sTickerName, "B", CurrentPrice) == "") then
			iVolume = tonumber(iVolume)+aLotSize[sTickerName];
			SetValueToFile(ParamPath..sTickerName.."_LastPrice.txt", CurrentPrice)
			SetValueToFile(ParamPath..sTickerName.."_LastDirection.txt", "B")
			SetValueToFile(ParamPath..sTickerName.."_Volume.txt", tostring(iVolume))
			LastPrice = CurrentPrice; -- ����� �� ������� ����� �� ��������� �������.
		end
	end
	
	-- ������ ���������, �� ���� �� ��� �������? ���� ���� ����, �� �������� � ����
	if (( (CurrentPrice>LastPrice+FiboLevels(sTickerName) and iVolume>maxVolume) or (CurrentPrice>LastPrice+FiboSize(sTickerName) and LastDirection=="B" and iVolume>maxVolume) ) or (iVolume==0 and CurrentPrice>aStartPrice[sTickerName])) and PriceEnterToBollingerFromUp(sTickerName) then
		-- �������
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

function FiboLevels (sTickerName) -- ������� ���������� ������� ������ � ����������� �� ������� �� ������
  local Volume = math.abs(tonumber(iVolume / aLotSize[sTickerName])); 
  local iniStepSize = fiboStepSize[sTickerName];
  local newStepSize = iniStepSize + (iniStepSize * fibo)^Volume;
  return newStepSize;
end;  

function FiboSize (sTickerName) -- ������� ����������� ������ ����� ������� ����������
 local CurrentPrice=GetLastPrice(sTickerName, "OPEN") -- ����������� �� ������� ������� ����.
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