package  
{
    /**
     * Simple Yeelight box connector and protocol stack
     * @author Shikai Chen (CSK)
     * http://www.csksoft.net
     * 
     * It seems the yeebox use the same protocol as the one between the AVR and CC2530 serial inside the box
     * 
     */
    
     
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.net.Socket;
    import flash.utils.Endian;
    
    public class YeelightConnector
    {
        public static const YEEBOX_SERVER_PORT:int = 10003;
        
        public static const YEELIGHT_CMD_CONTROL:String = "C";
        public static const YEELIGHT_CMD_STATUS:String = "S";
        public static const YEELIGHT_CMD_DEVICELIST:String = "GL";
        
        private var _serverip:String = "";
        private var _is_connected:Boolean = false;
        
        private var _recv_line:String = "";
        
        private var _socket:Socket = null;
        private var _funcAfter:Function = null;
        private var _funcRecv:Function = null;
        
        private function onConnection(evt:Event):void
        {
            Main._msgbox.text = "Connection to " + _serverip +" establised.";
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
        
        private function onRecvGeneral(evt:Event):void
        {
            
            var current_char:int = 0;
            var count:int = 0;
            while ( _socket.bytesAvailable>0)
            {
                current_char = _socket.readByte();
                if ( current_char == '\n'.charCodeAt())
                {
                   // Main._msgbox.text = _recv_line;
                   // _funcRecv(_recv_line);
                    _recv_line = "";
                    continue;
                }
                _recv_line += String.fromCharCode(current_char);
            }
            

        }
        
        public function YeelightConnector() 
        {
            _serverip = "";
        }
        
        public function setLightBrightness(id:int, brightness:int, funcAfter:Function = null):void
        {
            if (!_is_connected) return;
            _funcAfter = funcAfter;
            _funcRecv  = onGeneralResult;
            
            var strID:String = "0000" + id.toString();
            strID = strID.substr(strID.length-4, 4);
            
            _socket.writeUTFBytes(YEELIGHT_CMD_CONTROL + " " + strID +",,,," + brightness + ",,\n");
            _socket.flush();
       
        }
        
        public function enableLight(id:int, funcAfter:Function = null):void
        {
            setLightBrightness(id, 100, funcAfter);
        }
        
        public function disableLight(id:int, funcAfter:Function = null):void
        {
            setLightBrightness(id, 0, funcAfter);
        }
        
        public function setRGB(id:int, r:int, g:int, b:int, lux:int, funcAfter:Function = null):void
        {
            if (!_is_connected) return;
            _funcAfter = funcAfter;
            _funcRecv  = onGeneralResult;
            
            
            var strID:String = "0000" + id.toString();
            strID = strID.substr(strID.length - 4, 4);
          //  Main._msgbox.text = YEELIGHT_CMD_CONTROL + " " + strID +"," + r + "," + g + "," + b + ",100,,\n";
            _socket.writeUTFBytes(YEELIGHT_CMD_CONTROL + " " + strID +"," + r + "," + g + "," + b + ",100,,\n");
            _socket.flush();
        }
  
        public function setHSV(id:int, h:Number, s:Number, v:Number, funcAfter:Function = null):void
        {
            var rgbArray:Array = hsv(h, s, v);
            setRGB(id, rgbArray[0], rgbArray[1], rgbArray[2], v*100, funcAfter);
            
        }
        public function connect(srv_ip:String, funcAfter:Function = null):Boolean
        {
            _is_connected = false;
            _serverip = srv_ip;
            _socket = new Socket();
            
            if (!_socket) return false;
            
            _socket.endian = Endian.LITTLE_ENDIAN;
            _socket.addEventListener(Event.CONNECT, onConnection);
            _socket.addEventListener(ProgressEvent.SOCKET_DATA, onRecvGeneral);
            _socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
            
            _recv_line = "";
            _funcAfter = funcAfter;
            _socket.connect(_serverip , YEEBOX_SERVER_PORT)
            _is_connected = false;
            return true;
        }
        
        private function hsv(h:Number, s:Number, v:Number):Array
        {
            var r:Number, g:Number, b:Number;
            var i:int;
            var f:Number, p:Number, q:Number, t:Number;
             
            if (s == 0){
                r = g = b = v;
                return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
            }
           
            h /= 60;
            i  = Math.floor(h);
            f = h - i;
            p = v *  (1 - s);
            q = v * (1 - s * f);
            t = v * (1 - s * (1 - f));
           
            switch( i ) {
                case 0:
                    r = v;
                    g = t;
                    b = p;
                    break;
                case 1:
                    r = q;
                    g = v;
                    b = p;
                    break;
                case 2:
                    r = p;
                    g = v;
                    b = t;
                    break;
                case 3:
                    r = p;
                    g = q;
                    b = v;
                    break;
                case 4:
                    r = t;
                    g = p;
                    b = v;
                    break;
                default:        // case 5:
                    r = v;
                    g = p;
                    b = q;
                    break;
            }
            return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
        }        
    }

}