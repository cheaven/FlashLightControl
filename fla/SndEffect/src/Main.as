package 
{
    import flash.net.URLLoader;
    import flash.utils.*;
    import flash.display.*;
    import flash.events.*;
    import flash.geom.*
    import flash.media.*;
    import flash.net.URLRequest;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.utils.ByteArray;
    /**
     * A small demo utilizes the FFT feature
     * @author Shikai Chen
     * csk@live.com
     * http://www.csksoft.net
     */
    

     
    public class Main extends Sprite 
    {

        ///////////////////////////
        private static const JARID_RIGHT:int = 1;
        private static const JARID_LEFT:int = 2;
        
        
        ///////////////////////////
        
        protected var _bk:Shape;
        protected var _jar_indicator_l:Shape;
        protected var _jar_indicator_r:Shape;
        protected var _drawer:Sprite;
        protected var _snd:Sound;
        public static var _msgbox:TextField;
        
      //  protected var _bridge_connect:SunjarppConnector;
        protected var _ebox_connect:YeelightConnector;
        
        
        protected var _is_jar1_ready:Boolean = false;
        protected var _is_jar2_ready:Boolean = false;
        
        public function Main():void 
        {
            if (stage) init();
            else addEventListener(Event.ADDED_TO_STAGE, init);
        }
        private function playSnd(url:String):void
        {
            _snd = new Sound(new URLRequest(url));
            _snd.addEventListener(Event.COMPLETE, function(e:Event):void
            {
                var channel:SoundChannel = _snd.play();
            });
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        private function power2Brightness(pwr:Number, sample_duration:int):Number {
            
            var raw_val:Number;
            /*
            if (pwr == 0)
            {
                return 0;
            }else {
                raw_val = Math.log(pwr / sample_duration)/2+1;
                //if (raw_val < 0) return 0;
            
                return pwr;
            }
            */
            return pwr * 2;
        }
        
        private var current_jar_fresh_cnt:int = 0;
        private var total_pwr_l:Number = 0;
        private var total_pwr_r:Number = 0;
        private var total_band_l:Number = 0;
        private var total_band_r:Number = 0;
 
        
        public const PLOT_HEIGHT:int = 150;
        public const CHANGEL_WIDTH:int = 300;
        public const CHANNEL_LENGTH:int = 256;
        public const SAMPLE_INTERVAL:int = 4;
            
        public const JAR_FRESH_RATE:int = 4;
        


            
        private function onEnterFrame(event:Event):void {
            var bytes:ByteArray = new ByteArray();

            
            
            current_jar_fresh_cnt ++;
            
            var circle_d:int = CHANGEL_WIDTH / (CHANNEL_LENGTH / SAMPLE_INTERVAL);
            SoundMixer.computeSpectrum(bytes, true, 0);    //FFT transform, window size: 512, 2 channel, 44Khz
            var g:Graphics = _drawer.graphics;
            g.clear();
            var n:Number = 0;
            g.beginFill(0xFFFFFF, 0.5);
            for (var i:int = 0; i < CHANGEL_WIDTH*2; i+=SAMPLE_INTERVAL) {
                    g.drawCircle(  (i/SAMPLE_INTERVAL + 1 / 2) * circle_d, PLOT_HEIGHT , circle_d / 2-0.5 );
            }       
            g.endFill();
            
            var freq_end_point:int;
            var brightness_val:Number;
            freq_end_point = 0;
            for (i = 0; i < CHANNEL_LENGTH; i+=SAMPLE_INTERVAL) {
                var avg:Number = 0;
                var cur:Number = 0;
                for ( var c:int = 0 ; c < SAMPLE_INTERVAL; c++)  { 
                    avg += (cur = bytes.readFloat());
                    if (cur > 0) freq_end_point++;
                    
                }
                total_pwr_l += avg;
                avg /= SAMPLE_INTERVAL;
                
                var cir_cnt:int = avg * PLOT_HEIGHT / circle_d ;
                
                g.beginFill(0xFFFFFF, 1- avg);
                for ( c = 0; c < cir_cnt; c++)
                {
                    g.drawCircle( CHANGEL_WIDTH - (i/SAMPLE_INTERVAL + 1 / 2) * circle_d, PLOT_HEIGHT - (c + 1) * circle_d , circle_d / 2-0.5 );
                    g.drawCircle( CHANGEL_WIDTH - (i/SAMPLE_INTERVAL + 1 / 2) * circle_d, PLOT_HEIGHT + (c + 1) * circle_d, circle_d / 2 -0.5 );
                }
                g.endFill();
            }
            if (total_band_l < freq_end_point) {
                total_band_l = freq_end_point;
            }else {
                total_band_l += (freq_end_point - total_band_l) * 0.02;
            }
            
            if ((current_jar_fresh_cnt % JAR_FRESH_RATE) == 0) {
                
                drawJarIndicator( 270 - total_band_l * 360 / (CHANNEL_LENGTH), power2Brightness(total_pwr_l / CHANNEL_LENGTH, 1) , 0);
                //if (_is_jar1_ready)
                //_bridge_connect.SetHSV( 5,270-total_band_l * 360 / (CHANNEL_LENGTH), 255, power2Brightness(total_pwr_l / CHANNEL_LENGTH, 1) * 255, null);
                
             //   _ebox_connect.setHSV(JARID_LEFT, 270 - total_band_l * 360 / (CHANNEL_LENGTH), 1 , power2Brightness(total_pwr_l / CHANNEL_LENGTH, 1) );
                
                
                total_pwr_l = 0;
            //    total_band_l = 0;
            }
            freq_end_point = 0;
            for (i=0; i < CHANNEL_LENGTH; i+=SAMPLE_INTERVAL) {
                avg = 0;
                for ( c = 0 ; c < SAMPLE_INTERVAL; c++)  { 
                    avg += (cur = bytes.readFloat());
                    if (cur > 0) freq_end_point++;
                }
                total_pwr_r += avg;
                avg /= SAMPLE_INTERVAL;
                cir_cnt = avg * PLOT_HEIGHT / circle_d ;
                if (cir_cnt > 0) freq_end_point = i;
                
                g.beginFill(0xFFFFFF, 1- avg);
                for ( c = 0; c < cir_cnt; c++)
                {
                    g.drawCircle( CHANGEL_WIDTH + (i/SAMPLE_INTERVAL + 1 / 2) * circle_d, PLOT_HEIGHT - (c + 1) * circle_d, circle_d / 2-0.5 );
                    g.drawCircle( CHANGEL_WIDTH +  (i / SAMPLE_INTERVAL + 1 / 2) * circle_d, PLOT_HEIGHT + (c + 1) * circle_d, circle_d / 2 -0.5 );
                }    
                g.endFill();
            }   
            
            if (total_band_r < freq_end_point) {
                total_band_r = freq_end_point;
            }else {
                total_band_r += (freq_end_point - total_band_r) * 0.02;
            }
            
            if ((current_jar_fresh_cnt % JAR_FRESH_RATE) == 0) {
                
                drawJarIndicator( 270 - total_band_r * 270 / (CHANNEL_LENGTH), power2Brightness(total_pwr_r / CHANNEL_LENGTH, 1) , 1);
                //if (_is_jar2_ready)
                //_bridge_connect.SetHSV( 6,270-total_band_r * 270 / (CHANNEL_LENGTH), 255, power2Brightness(total_pwr_r / CHANNEL_LENGTH, 1) * 255, null);
               
                _ebox_connect.setHSV(JARID_RIGHT, 270 - total_band_r *  270 / (CHANNEL_LENGTH), 1 , power2Brightness(total_pwr_r / CHANNEL_LENGTH, 1) );

                total_pwr_r = 0;
            //    total_band_l = 0;
            }
        }
        private function init(e:Event = null):void 
        {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            //_bridge_connect = new SunjarppConnector();
            _ebox_connect = new YeelightConnector();
            
            makestage();
            playSnd("media/music.mp3");
        }

        //private function onConnected(result:Boolean):void
        //{
            //var This:Main = this;
            //function onSunjarConnection1(result:Boolean):void
            //{
                ///*
                //_bridge_connect.GetTemperature(5, function(ans:Boolean, val:Number):void {
                    //_msgbox.text = "Retrieved temperature data: " + val.toString();
                //});
                //*/
                //setTimeout( function():void { _bridge_connect.ConnectSunjar(6, onSunjarConnection2); }, 100);
                //if (!result) {
                    //return ;
                //}
                //_is_jar1_ready = true;
                //_bridge_connect.SetLightingMode(5, SunjarppConnector.LIGHT_MODE_CONSTANT, function(ans:Boolean):void {
                    //
                //});            
            //}
            //
            //function onSunjarConnection2(result:Boolean):void
            //{
            //
                //if (!result) {
                    //return ;
                //}
                //
                //_is_jar2_ready = true;
                //_bridge_connect.SetLightingMode(6, SunjarppConnector.LIGHT_MODE_CONSTANT, function(ans:Boolean):void {
                    //
                //});    
            //}
            //_bridge_connect.ConnectSunjar(5, onSunjarConnection1);
            //
        //}
//
        
        private function onConnected(result:Boolean):void
        {
            var This:Main = this;
            this._ebox_connect.enableLight(JARID_RIGHT);
            this._ebox_connect.enableLight(JARID_LEFT);
        }
        
        private function makestage():void
        {
            _bk = new Shape();
            var fillType:String = GradientType.LINEAR;
            var colors:Array = [0x1f7ddd, 0x042046 ,0x1f7ddd];
            var alphas:Array = [1, 1, 1];
            var ratios:Array = [0x00, 0x80 ,0xFF];
            var matr:Matrix = new Matrix();
            matr.createGradientBox(600, 300,Math.PI / 2, 0, 0);
            var spreadMethod:String = SpreadMethod.PAD;
            _bk.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);       
            _bk.graphics.drawRect(0, 0, 600, 300);
            this.addChild(_bk);
            _drawer = new Sprite();
            this.addChild(_drawer);
            _msgbox = new TextField();
            this.addChild(_msgbox);

            _msgbox.textColor = 0xFFFFFFFF;
            _msgbox.width = 400;
            
            _msgbox.defaultTextFormat = new TextFormat("Arial")
            //_bridge_connect.Connect(onConnected);    
            
            var configLoader:URLLoader = new URLLoader();
            configLoader.addEventListener(Event.COMPLETE, function(event:Event):void {
                
                _ebox_connect.connect(configLoader.data, onConnected);
            });
            
            configLoader.load(new URLRequest("config.txt"));
            
           // 
            
            _jar_indicator_l = new Shape();
            _jar_indicator_r = new Shape();
            
            this.addChild(_jar_indicator_l);
            this.addChild(_jar_indicator_r);
            
        //    _jar_indicator_l.width = _jar_indicator_r.width = _jar_indicator_l.height = _jar_indicator_r.height = 20;
            _jar_indicator_l.y = _jar_indicator_r.y = 20;
            _jar_indicator_l.x = 20;
            _jar_indicator_r.x = this.width - 20 - 40;
            

        }
        
        private function drawJarIndicator( hue:int, brightness:Number, id:int):void
        {
            var theIndicator:Shape;
            if (id == 0) theIndicator = _jar_indicator_l;
            else  theIndicator = _jar_indicator_r;
            var converted_rgb:Array = hsv(hue, 1, brightness);
            
            theIndicator.graphics.clear();
            theIndicator.graphics.beginFill( converted_rgb[0]<<16 | converted_rgb[1]<<8 | converted_rgb[2] );
            theIndicator.graphics.drawRoundRect(0, 0, 40, 40, 5, 5);
            theIndicator.graphics.endFill();
        }
        private function drawJarIndicator2( r:int,g:int,b:int, id:int):void
        {
            var theIndicator:Shape;
            if (id == 0) theIndicator = _jar_indicator_l;
            else  theIndicator = _jar_indicator_r;
    
            
            theIndicator.graphics.clear();
            theIndicator.graphics.beginFill( r<<16 | g<<8 | b );
            theIndicator.graphics.drawRoundRect(0, 0, 40, 40, 5, 5);
            theIndicator.graphics.endFill();
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