require 'socket'
require 'base64'
require 'json'

module HS1xx
  class Plug

    def initialize(ip_address)
      @ip_address = ip_address
    end
    
    # System commands
    #========================================
    
    #Get System Info (Software & Hardware Versions, MAC, deviceID, hwID etc.)
    def sys_info
      send_to_plug(:system => {:get_sysinfo => {}})
    end

    #Reboot
    def sys_reboot
      send_to_plug(:system => {:reboot => {:delay => 1}})
    end

    #Reset (To Factory Settings)
    def sys_reset
      send_to_plug(:system => {:reset => {:delay => 1}})
    end
    
    #Turn On
    def on
      send_to_plug(:system => {:set_relay_state => {:state => 1}})
    end
    
    #Turn Off
    def off
      send_to_plug(:system => {:set_relay_state => {:state => 0}})
    end
    
    def on?
      status = send_to_plug(:system => {:get_sysinfo => {}})
      status['system']['get_sysinfo']['relay_state'] == 1
    end

    def off?
      !on?
    end
    
    #Set Device Alias
    def sys_alias(name)
      send_to_plug(:system => {:set_dev_alias => {:alias => name}})
    end
    
    #Set MAC Address
    def sys_set_mac(mac)
      send_to_plug(:system => {:set_mac_addr => {:mac => mac}})
    end

    #Set Device ID
    def sys_set_devid(id)
      send_to_plug(:system => {:set_device_id => {:deviceId => id}})
    end

    #Set Hardware ID
    def sys_set_hwid(id)
      send_to_plug(:system => {:set_hw_id => {:hwId => id}})
    end

    #Set Location
    def sys_set_location(longitude, latitude)
      send_to_plug(:system => {:set_dev_location => {:longitude => longitude, :latitude => latitude}})
    end

    #Perform uBoot Bootloader Check
    def sys_check_uboot
      send_to_plug(:system => {:test_check_uboot => {}})
    end

    #Get Device Icon
    def sys_get_icon
      send_to_plug(:system => {:get_dev_icon => {}})
    end
    
    #Set Device Icon
    def sys_set_icon(icon, hash)
      send_to_plug(:system => {:set_dev_icon => {:icon => icon, :hash => hash}})
    end

    #Set Test Mode (command only accepted coming from IP 192.168.1.100)
    def sys_set_test_mode
      send_to_plug(:system => {:set_test_mode => {:enable => 1}})
    end

    #Download Firmware from URL
    def sys_download_fw(url)
      send_to_plug(:system => {:downlod_firmware => {:url => url}})
    end

    #Get Download State
    def sys_get_download_state
      send_to_plug(:system => {:get_download_state => {}})
    end

    #Flash Downloaded Firmware
    def sys_flash_firmware
      send_to_plug(:system => {:flash_firmware => {}})
    end

    #Check Config
    def sys_check_config
      send_to_plug(:system => {:check_new_config => {}})
    end
    
    #WLAN Commands
    #========================================
    
    #Scan for list of available APs
    def wifi_scan
      send_to_plug(:netif => {:get_scaninfo => {:refresh => 1}})
    end

    #Connect to AP with given SSID and Password
    def wifi_connect(ssid, password, key_type) # key_type of 3 is for WPA2-PSK
      send_to_plug(:netif => {:set_stainfo => {:ssid => ssid, :password => password, :key_type => key_type}})
    end
    
    #EMeter Energy Usage Statistics Commands
    #(for TP-Link HS110)
    #========================================
    
    #Get EMeter VGain and IGain Settings
    def emeter_get_vgain_igain
      send_to_plug(:emeter => {:get_vgain_igain => {}})
    end

    #Set EMeter VGain and Igain
    def emeter_set_vgain_igain(vgain, igain)
      send_to_plug(:emeter => {:set_vgain_igain => {:vgain => vgain, :igain => igain}})
    end

    #Start EMeter Calibration
    def emeter_calibrate(vtarget, itarget)
      send_to_plug(:emeter => {:start_calibration => {:vtarget => vtarget, :itarget => itarget}})
    end

    #Get Realtime Current and Voltage Reading
    def emeter_realtime
      send_to_plug(:emeter => {:get_realtime => {}})
    end
    
    #Get Daily Statistic for given Month
    def emeter_get_day_stats(date) # Accepts a Time object
      send_to_plug(:emeter => {:get_daystat => {:month => date.month, :year => date.year}})
    end
    
    #Get Montly Statistic for given Year
    def emeter_get_month_stats(date) # Accepts a Time object
      send_to_plug(:emeter => {:get_monthstat => {:year => date.year}})
    end
    
    #Erase All EMeter Statistics
    def emeter_erase_stats
      send_to_plug(:emeter => {:erase_emeter_stat => {}})
    end
    
    #Time Commands
    #========================================
    
    #Get Time
    def get_time
      send_to_plug(:time => {:get_time =>{}})
    end
    
    #Get Timezone
    def get_timezone
      send_to_plug(:time => {:get_timezone =>{}})
    end
    
    #Set Timezone
    def set_timezone(date, index) # Need timezone index i.e. https://support.microsoft.com/en-gb/help/973627/microsoft-time-zone-index-values
      send_to_plug(:time => {:set_timezone => {:year => date.year, :month => date.month, :mday => date.mday, :hour => date.hour, :min => date.min, :sec => date.sec, :index => index}})
    end
    
    #Schedule Commands
    #(action to perform regularly on given weekdays)
    #========================================
    #Get Next Scheduled Action
    #{"schedule":{"get_next_action":null}}
    #
    #Get Schedule Rules List
    #{"schedule":{"get_rules":null}}
    #
    #Add New Schedule Rule
    #{"schedule":{"add_rule":{"stime_opt":0,"wday":[1,0,0,1,1,0,0],"smin":1014,"enable":1,"repeat":1,"etime_opt":-1,"name":"lights on","eact":-1,"month":0,"sact":1,"year":0,"longitude":0,"day":0,"force":0,"latitude":0,"emin":0},"set_overall_enable":{"enable":1}}}
    #
    #Edit Schedule Rule with given ID
    #{"schedule":{"edit_rule":{"stime_opt":0,"wday":[1,0,0,1,1,0,0],"smin":1014,"enable":1,"repeat":1,"etime_opt":-1,"id":"4B44932DFC09780B554A740BC1798CBC","name":"lights on","eact":-1,"month":0,"sact":1,"year":0,"longitude":0,"day":0,"force":0,"latitude":0,"emin":0}}}
    #
    #Delete Schedule Rule with given ID
    #{"schedule":{"delete_rule":{"id":"4B44932DFC09780B554A740BC1798CBC"}}}
    #
    #Delete All Schedule Rules and Erase Statistics
    #{"schedule":{"delete_all_rules":null,"erase_runtime_stat":null}}
    
    #Countdown Rule Commands
    #(action to perform after number of seconds)
    #========================================
    #Get Rule (only one allowed)
    #{"count_down":{"get_rules":null}}
    #
    #Add New Countdown Rule
    #{"count_down":{"add_rule":{"enable":1,"delay":1800,"act":1,"name":"turn on"}}}
    #
    #Edit Countdown Rule with given ID
    #{"count_down":{"edit_rule":{"enable":1,"id":"7C90311A1CD3227F25C6001D88F7FC13","delay":1800,"act":1,"name":"turn on"}}}
    #
    #Delete Countdown Rule with given ID
    #{"count_down":{"delete_rule":{"id":"7C90311A1CD3227F25C6001D88F7FC13"}}}
    #
    #Delete All Coundown Rules
    #{"count_down":{"delete_all_rules":null}}
    
    #Anti-Theft Rule Commands (aka Away Mode) 
    #(period of time during which device will be randomly turned on and off to deter thieves) 
    #========================================
    #Get Anti-Theft Rules List
    #{"anti_theft":{"get_rules":null}}
    #
    #Add New Anti-Theft Rule
    #{"anti_theft":{"add_rule":{"stime_opt":0,"wday":[0,0,0,1,0,1,0],"smin":987,"enable":1,"frequency":5,"repeat":1,"etime_opt":0,"duration":2,"name":"test","lastfor":1,"month":0,"year":0,"longitude":0,"day":0,"latitude":0,"force":0,"emin":1047},"set_overall_enable":1}}
    #
    #Edit Anti-Theft Rule with given ID
    #{"anti_theft":{"edit_rule":{"stime_opt":0,"wday":[0,0,0,1,0,1,0],"smin":987,"enable":1,"frequency":5,"repeat":1,"etime_opt":0,"id":"E36B1F4466B135C1FD481F0B4BFC9C30","duration":2,"name":"test","lastfor":1,"month":0,"year":0,"longitude":0,"day":0,"latitude":0,"force":0,"emin":1047},"set_overall_enable":1}}
    #
    #Delete Anti-Theft Rule with given ID
    #{"anti_theft":{"delete_rule":{"id":"E36B1F4466B135C1FD481F0B4BFC9C30"}}}
    #
    #Delete All Anti-Theft Rules
    #"anti_theft":{"delete_all_rules":null}}
    
    private

    def send_to_plug(payload)
      payload = payload.to_json
      socket = TCPSocket.new(@ip_address, 9999)
      socket.puts(encrypt(payload))
      decrypt(socket.gets)
    ensure
      socket.close rescue nil
    end

    def encrypt(payload)
      output = []
      key = 0xAB
      payload.bytes do |b|
        output << (b ^ key)
        key = (b ^ key)
      end
      a = [output.size, *output]
      a.pack('NC*')
    end

    def decrypt(payload)
      key = 0xAB
      array = []
      payload.bytes[4..-1].each do |b, i|
        array << (b ^ key)
        key = b
      end
      result = array.pack('C*')
      JSON.parse(result)
    end
  end
end
