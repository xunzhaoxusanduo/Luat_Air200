--[[
ģ�����ƣ���Ƶ����
ģ�鹦�ܣ�dtmf����롢tts����Ҫ�ײ�����֧�֣�����Ƶ�ļ��Ĳ��ź�ֹͣ��¼����mic��speaker�Ŀ���
ģ������޸�ʱ�䣺2017.02.20
]]

--����ģ��,����������
local base = _G
local string = require"string"
local io = require"io"
local rtos = require"rtos"
local audio = require"audiocore"
local sys = require"sys"
local ril = require"ril"
module("audio")

--���س��õ�ȫ�ֺ���������
local smatch = string.match
local print = base.print
local dispatch = sys.dispatch
local req = ril.request
local tonumber = base.tonumber

--speakervol��speaker�����ȼ���ȡֵ��ΧΪaudio.VOL0��audio.VOL7��audio.VOL0Ϊ����
--audiochannel����Ƶͨ������Ӳ������йأ��û�������Ҫ����Ӳ������
--microphonevol��mic�����ȼ���ȡֵ��ΧΪaudio.MIC_VOL0��audio.MIC_VOL15��audio.MIC_VOL0Ϊ����
local speakervol,audiochannel,microphonevol = audio.VOL4,audio.HANDSET,audio.MIC_VOL15
-- GSMȫ����ģʽ
local gsmfr = false 
local ttscause
--��Ƶ�ļ�·��
local playname

--[[
��������setGSMFR
����  ������GSMȫ���ʣ�Ŀǰ������Ч��
����  ����		
����ֵ����
]]
function setGSMFR()
	gsmfr = true
	req([[AT+SCFG="Call/SpeechVersion1",2]])
end

--[[
��������dtmfdetect
����  ������dtmf����Ƿ�ʹ���Լ�������
����  ��
		enable��trueʹ�ܣ�false����nilΪ��ʹ��
		sens�������ȣ�Ĭ��3��������Ϊ1
����ֵ����
]]
function dtmfdetect(enable,sens)
	if enable == true then
		if not gsmfr then setGSMFR() end

		if sens then
			req("AT+DTMFDET=2,1," .. sens)
		else
			req("AT+DTMFDET=2,1,3")
		end
	end

	req("AT+DTMFDET="..(enable and 1 or 0))
end

--[[
��������senddtmf
����  ������dtmf���Զ�
����  ��
		str��dtmf�ַ���
		playtime��ÿ��dtmf����ʱ�䣬��λ���룬Ĭ��100
		intvl������dtmf�������λ���룬Ĭ��100
����ֵ����
]]
function senddtmf(str,playtime,intvl)
	if string.match(str,"([%dABCD%*#]+)") ~= str then
		print("senddtmf: illegal string "..str)
		return false
	end

	playtime = playtime and playtime or 100
	intvl = intvl and intvl or 100

	req("AT+SENDSOUND="..string.format("\"%s\",%d,%d",str,playtime,intvl))
end

--[[
��������playtts
����  ������tts
����  ��
		text���ַ���
		path��"net"��ʾ���粥�ţ�����ֵ��ʾ���ز���
����ֵ��true
]]
function playtts(text,path)
	local action = path == "net" and 4 or 2

	req("AT+QTTS=1")
	req(string.format("AT+QTTS=%d,\"%s\"",action,text))
	return true
end

--[[
��������stoptts
����  ��ֹͣ����tts
����  ����
����ֵ����
]]
function stoptts()
	req("AT+QTTS=3")
end

--[[
��������closetts
����  ���ر�tts����
����  ��
		cause���ر�ԭ��
����ֵ����
]]
function closetts(cause)
	ttscause = cause
	req("AT+QTTS=0")
end

--[[
��������transvoice
����  ��ͨ���з����������Զ�,������12.2K AMR��ʽ
����  ��
����ֵ��trueΪ�ɹ���falseΪʧ��
]]
function transvoice(data,loop,loop2)
	local f = io.open("/RecDir/rec000","wb")

	if f == nil then
		print("transvoice:open file error")
		return false
	end

	-- ���ļ�ͷ������12.2K֡
	if string.sub(data,1,7) == "#!AMR\010\060" then
	-- ���ļ�ͷ����12.2K֡
	elseif string.byte(data,1) == 0x3C then
		f:write("#!AMR\010")
	else
		print("transvoice:must be 12.2K AMR")
		return false
	end

	f:write(data)
	f:close()

	req(string.format("AT+AUDREC=%d,%d,2,0,50000",loop2 == true and 1 or 0,loop == true and 1 or 0))

	return true
end

--[[
��������beginrecord
����  ����ʼ¼��
����  ��
		id��¼��id����������id�洢¼���ļ���ȡֵ��Χ0-4
		duration��¼��ʱ������λ����
����ֵ��true
]]
function beginrecord(id,duration)
	req(string.format("AT+AUDREC=0,0,1," .. id .. "," .. duration))
	return true
end

--[[
��������endrecord
����  ������¼��
����  ��
		id��¼��id����������id�洢¼���ļ���ȡֵ��Χ0-4
		duration��¼��ʱ������λ����
����ֵ��true
]]
function endrecord(id,duration)
	req(string.format("AT+AUDREC=0,0,0," .. id .. "," .. duration))
	return true
end

--[[
��������delrecord
����  ��ɾ��¼���ļ�
����  ��
		id��¼��id����������id�洢¼���ļ���ȡֵ��Χ0-4
		duration��¼��ʱ������λ����
����ֵ��true
]]
function delrecord(id,duration)
	req(string.format("AT+AUDREC=0,0,4," .. id .. "," .. duration))
	return true
end

--[[
��������playrecord
����  ������¼���ļ�
����  ��
		dl��ģ�����У��������ֱ������ȣ��Ƿ��������¼�����ŵ�������true����������false����nil������
		loop���Ƿ�ѭ�����ţ�trueΪѭ����false����nilΪ��ѭ��
		id��¼��id����������id�洢¼���ļ���ȡֵ��Χ0-4
		duration��¼��ʱ������λ����
����ֵ��true
]]
function playrecord(dl,loop,id,duration)
	req(string.format("AT+AUDREC=" .. (dl and 1 or 0) .. "," .. (loop and 1 or 0) .. ",2," .. id .. "," .. duration))
	return true
end

--[[
��������stoprecord
����  ��ֹͣ����¼���ļ�
����  ��
		dl��ģ�����У��������ֱ������ȣ��Ƿ��������¼�����ŵ�������true����������false����nil������
		loop���Ƿ�ѭ�����ţ�trueΪѭ����false����nilΪ��ѭ��
		id��¼��id����������id�洢¼���ļ���ȡֵ��Χ0-4
		duration��¼��ʱ������λ����
����ֵ��true
]]
function stoprecord(dl,loop,id,duration)
	req(string.format("AT+AUDREC=" .. (dl and 1 or 0) .. "," .. (loop and 1 or 0) .. ",3," .. id .. "," .. duration))
	return true
end

--[[
function playamfgp(namepath,typ)
	req(string.format("AT+AMFGP=1,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end

function stopamfgp(namepath,typ)
	req(string.format("AT+AMFGP=0,\"".. namepath .. "\"," .. (typ and typ or 1)))
	return true
end
]]

--[[
��������play
����  ��������Ƶ�ļ�
����  ��
		name����Ƶ�ļ�·��
		loop���Ƿ�ѭ�����ţ�trueΪѭ����false����nilΪ��ѭ��
����ֵ�����ò��Žӿ��Ƿ�ɹ���trueΪ�ɹ���falseΪʧ��
]]
function play(name,loop)
	if loop then playname = name end
	return audio.play(name)
end

--[[
��������stop
����  ��ֹͣ������Ƶ�ļ�
����  ����
����ֵ������ֹͣ���Žӿ��Ƿ�ɹ���trueΪ�ɹ���falseΪʧ��
]]
function stop()
	playname = nil
	return audio.stop()
end

local dtmfnum = {[71] = "Hz1000",[69] = "Hz1400",[70] = "Hz2300"}

--[[
��������parsedtmfnum
����  ��dtmf���룬����󣬻����һ���ڲ���ϢAUDIO_DTMF_DETECT��Я��������DTMF�ַ�
����  ��
		data��dtmf�ַ�������
����ֵ����
]]
local function parsedtmfnum(data)
	local n = base.tonumber(string.match(data,"(%d+)"))
	local dtmf

	if (n >= 48 and n <= 57) or (n >=65 and n <= 68) or n == 42 or n == 35 then
		dtmf = string.char(n)
	else
		dtmf = dtmfnum[n]
	end

	if dtmf then
		dispatch("AUDIO_DTMF_DETECT",dtmf)
	end
end

--[[
��������audiourc
����  ��������ģ���ڡ�ע��ĵײ�coreͨ�����⴮�������ϱ���֪ͨ���Ĵ���
����  ��
		data��֪ͨ�������ַ�����Ϣ
		prefix��֪ͨ��ǰ׺
����ֵ����
]]
local function audiourc(data,prefix)
	--DTMF���ռ��
	if prefix == "+DTMFDET" then
		parsedtmfnum(data)
	--¼������¼�����Ź���
	elseif prefix == "+AUDREC" then
		local action,duration = string.match(data,"(%d),(%d+)")
		if action and duration then
			duration = base.tonumber(duration)
			--��ʼ¼��
			if action == "1" then
				dispatch("AUDIO_RECORD_IND",(duration > 0 and true or false),duration)
			--����¼��
			elseif action == "2" then
				if duration > 0 then
					dispatch("AUDIO_PLAY_END_IND")
				else
					dispatch("AUDIO_PLAY_ERROR_IND")
				end
			--ɾ��¼��
			elseif action == "4" then
				dispatch("AUDIO_RECORD_IND",true,duration)
			end
		end
	--tts����
	elseif prefix == "+QTTS" then
		local flag = string.match(data,": *(%d)",string.len(prefix)+1)
		--ֹͣ����tts
		if flag == "0" then
			dispatch("AUDIO_PLAY_END_IND")
		end
	--[[elseif prefix == "+AMFGP" then
		local action = string.match(data,": *(%d)",string.len(prefix)+1)
		if action then
			if action == "0" then
				dispatch("AUDIO_PLAY_END_IND")
			elseif action == "1" then
				dispatch("AUDIO_PLAY_ERROR_IND")
			end
		end]]
	end
end

--[[
��������audiorsp
����  ��������ģ���ڡ�ͨ�����⴮�ڷ��͵��ײ�core������AT�����Ӧ����
����  ��
		cmd����Ӧ���Ӧ��AT����
		success��AT����ִ�н����true����false
		response��AT�����Ӧ���е�ִ�н���ַ���
		intermediate��AT�����Ӧ���е��м���Ϣ
����ֵ����
]]
local function audiorsp(cmd,success,response,intermediate)
	local prefix = smatch(cmd,"AT(%+%u+%?*)")

	--¼�����߲���¼��ȷ��Ӧ��
	if prefix == "+AUDREC" then
		dispatch("AUDIO_RECORD_CNF",success)
	--����tts���߹ر�ttsӦ��
	elseif prefix == "+QTTS" then
		local action = smatch(cmd,"QTTS=(%d)")
		if not success then
			if action == "1" or action == "2" then
				--����ʧ�ܣ�����һ���ڲ���Ϣ
				dispatch("AUDIO_PLAY_ERROR_IND")
			end
		else
			if action == "0" then
				dispatch("TTS_CLOSE_IND",ttscause)
			end
		end
		if action=="3" then
			dispatch("TTS_STOP_IND")
		end
	end
end

--ע������֪ͨ�Ĵ�������
ril.regurc("+DTMFDET",audiourc)
ril.regurc("+AUDREC",audiourc)
--ril.regurc("+AMFGP",audiourc)
ril.regurc("+QTTS",audiourc)
--ע������AT�����Ӧ��������
ril.regrsp("+AUDREC",audiorsp,0)
ril.regrsp("+QTTS",audiorsp,0)

--[[
��������setspeakervol
����  ��������Ƶͨ�����������
����  ��
		vol�������ȼ���ȡֵ��ΧΪaudio.VOL0��audio.VOL7��audio.VOL0Ϊ����
����ֵ����
]]
function setspeakervol(vol)
	audio.setvol(vol)
	speakervol = vol
	--dispatch("SPEAKER_VOLUME_SET_CNF",true)
end

--[[
��������getspeakervol
����  ����ȡ��Ƶͨ�����������
����  ����
����ֵ�������ȼ�
]]
function getspeakervol()
	return speakervol
end

--[[
��������setaudiochannel
����  ��������Ƶͨ��
����  ��
		channel����Ƶͨ������Ӳ������йأ��û�������Ҫ����Ӳ�����ã�Air200ģ��͹̶���audiocore.HANDSET
����ֵ����
]]
function setaudiochannel(channel)
	audio.setchannel(channel)
	audiochannel = channel
	--dispatch("AUDIO_CHANNEL_SET_CNF",true)
end

--[[
��������getaudiochannel
����  ����ȡ��Ƶͨ��
����  ����
����ֵ����Ƶͨ��
]]
function getaudiochannel()
	return audiochannel
end

--[[
��������setloopback
����  �����ûػ�����
����  ��
		flag���Ƿ�򿪻ػ����ԣ�trueΪ�򿪣�falseΪ�ر�
		typ�����Իػ�����Ƶͨ������Ӳ������йأ��û�������Ҫ����Ӳ������
		setvol���Ƿ����������������trueΪ���ã�false������
		vol�����������
����ֵ��true���óɹ���false����ʧ��
]]
function setloopback(flag,typ,setvol,vol)
	return audio.setloopback(flag,typ,setvol,vol)
end

--[[
��������setmicrophonegain
����  ������MIC������
����  ��
		vol��mic�����ȼ���ȡֵ��ΧΪaudio.MIC_VOL0��audio.MIC_VOL15��audio.MIC_VOL0Ϊ����
����ֵ����
]]
function setmicrophonegain(vol)
	audio.setmicvol(vol)
	microphonevol = vol
	--dispatch("MICROPHONE_GAIN_SET_CNF",true)
end

--[[
��������getmicrophonegain
����  ����ȡMIC�������ȼ�
����  ����
����ֵ�������ȼ�
]]
function getmicrophonegain()
	return microphonevol
end

--[[
��������audiomsg
����  �������ײ��ϱ���rtos.MSG_AUDIO�ⲿ��Ϣ
����  ��
		msg��play_end_ind���Ƿ��������Ž���
		     play_error_ind���Ƿ񲥷Ŵ���
����ֵ����
]]
local function audiomsg(msg)
	if msg.play_end_ind == true then
		if playname then audio.play(playname) return end
		dispatch("AUDIO_PLAY_END_IND")
	elseif msg.play_error_ind == true then
		if playname then playname = nil end
		dispatch("AUDIO_PLAY_ERROR_IND")
	end
end

--ע��ײ��ϱ���rtos.MSG_AUDIO�ⲿ��Ϣ�Ĵ�������
sys.regmsg(rtos.MSG_AUDIO,audiomsg)
--Ĭ����Ƶͨ������ΪRECEIVER����ΪAir200ģ��ֻ֧��RECEIVERͨ��
setaudiochannel(audio.HANDSET)
--Ĭ�������ȼ�����Ϊ4����4�����м�ȼ������Ϊ0�������Ϊ7��
setspeakervol(audio.VOL4)