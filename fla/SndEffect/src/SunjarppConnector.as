package  
{
    /**
     * RoboPeak Qube NetBridge Connector
     * @author CSK
     */
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.Socket;
    import flash.utils.Endian;
    /*
    The procotol:
    
    The Sunjar Netbridge use a simple text-based streaming procotol.
    Each command request or response is a \n terminated line using the following format

    CommandID + ChannelNumber + " "  + Arg0 + " " + Arg1 + ... + "\n"

    The Response is the same:

    Result + " " + Result1 + " " + Result2 + ... + "\n"


    Avaliable CommandID:

    ID      |   Description                |  Arguments            |  Response
    --------+------------------------------+-----------------------+--------------------------------------
    0       |   Sunjar Connect    Request  |  n/a                  |  "ok" or "fail"
    1       |   Sunjar Dis-connect         |  n/a                  |  "ok"
    2       |   Get Temperature            |  n/a                  |  "ok" or "fail" + " " + tempval
    3       |   Set RGB                    |  A+" "+R+" "+G+" "+B  |  "ok" or "fail"
    4       |   Set HSV                    |  H+" "+S+" "+V        |  "ok" or "fail"
    5       |   Set Lighting Mode          |  Mode                 |  "ok" or "fail"
    6       |   Set Sunjar Channel         |  New Channel          |  "ok" or "fail"
*/
    public class SunjarppConnector
    {
        public static const  DEFAULT_BRIDGE_PORT:int = 18200;
    
        public static const  LIGHT_MODE_BEATING:int         = 0;
        public static const  LIGHT_MODE_BEATING_NO_CTRL:int = 1;
        public static const  LIGHT_MODE_CONSTANT:int        = 2;
        public static const  LIGHT_MODE_FLASHING:int        = 3;
        
        private static var recv_line:String = "";
        public function SunjarppConnector() 
        {
            _dest_addr = "";
            _dest_port = 0;
            _is_connected = false;
            
        }
        private function onConnection(evt:Event):void
        {
            Main._msgbox.text = "Connect to " + _dest_addr +" establised.";
            _is_connected = true;
            if (_funcAfter is Function)
            {
                _funcAfter(true);
            }
        }
        
        private function onIOError(evt:Event):void
        {
            _is_connected = false;
            if (_funcAfter is Function)
            {
                _funcAfter(false);
            }
        }
        private function onGeneralResult(cmd:String):void
        {
            if (_funcAfter is Function)
            {
                if (cmd.indexOf("ok")==0) {
                    
                    _funcAfter(true)
                }
                else
                    _funcAfter(false);
            }
        }
        
        
        private function onTemperatureResult(cmd:String):void
        {
            if (_funcAfter is Function)
            {
                var ans_arr:Array = cmd.split(" ");
                if (ans_arr.length>=2 && ans_arr[0] == "ok") 
                    _funcAfter(true, parseFloat(ans_arr[1]));
                else
                    _funcAfter(false, 0);
            }
        }
        
        
        private function onRecvGeneral(evt:Event):void
        {
            
            var current_char:int = 0;
            var count:int = 0;
            while ( _sock.bytesAvailable>0)
            {
                current_char = _sock.readByte();
                if ( current_char == '\n'.charCodeAt())
                {
                //    Main._msgbox.text = recv_line;
                    _funcRecv(recv_line);
                    recv_line = "";
                    continue;
                }
                recv_line += String.fromCharCode(current_char);
            }
            

        }
        public function Connect(funcAfter:Function, addr:String = "127.0.0.1", port:int = DEFAULT_BRIDGE_PORT):Boolean
        {
            _sock = new Socket();
            _sock.endian = Endian.BIG_ENDIAN;
            _dest_addr =  addr;
            _dest_port = port;
            if (_sock)
            {
                _sock.addEventListener(Event.CONNECT, onConnection);
                _sock.addEventListener(ProgressEvent.SOCKET_DATA, onRecvGeneral);
                _sock.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
                recv_line = "";
                _funcAfter = funcAfter;
                _sock.connect(_dest_addr , _dest_port)
                _is_connected = false;
                return true;
            }
            _is_connected = false;
            return false;
        }
            
        public function ConnectSunjar(id:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onGeneralResult;
                Main._msgbox.text = "Connecting the sunjar id:" + id + "...";
                
                _sock.writeUTFBytes("0 " + id +"\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        public function DisconnectJar(id:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onGeneralResult;
                Main._msgbox.text = "Disconnect the sunjar id:" + id + "...";
                
                _sock.writeUTFBytes("1 " + id +"\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        public function GetTemperature(id:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onTemperatureResult;
                Main._msgbox.text = "Ask the jar id:" + id + " about the temperature...";
                
                _sock.writeUTFBytes("2 " + id +"\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        public function SetRGB(id:int, red:int, green:int, blue:int, brightness:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onGeneralResult;
                
                if (red > 255) red = 255;
                if (green > 255) green = 255;
                if (blue > 255) blue = 255;
                _sock.writeUTFBytes("3 " + id +" " + brightness + " " + red + " " + green + " " + blue + "\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        public function SetHSV(id:int, hue:int, saturation:int, brightness:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onGeneralResult;
    
                if (hue >360) hue =360;
                if (hue < 0) hue = 0;
                if (brightness > 255) brightness = 255;
                if (saturation > 255) saturation = 255;
                
                _sock.writeUTFBytes("4 " + id +" " + hue + " " + saturation + " " + brightness + "\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        public function SetLightingMode(id:int, mode:int, funcAfter:Function):Boolean
        {
            if (_is_connected)
            {
                _funcAfter = funcAfter;
                _funcRecv  = onGeneralResult;
                
                
                _sock.writeUTFBytes("5 " + id +" " +mode + "\n");
                _sock.flush();
                return true;
            }
            return false;
        }
        
        protected var _funcAfter:Function;
        protected var _funcRecv:Function;
        protected var _dest_addr:String = "";
        protected var _dest_port:int = 0;
        protected var _is_connected:Boolean = false; 
        protected var _sock:Socket = null;
    }

}