package ;
import haxe.MainLoop;
import TelegramBotAPI;

class TelegramBotAPIExtractTest {

	private static inline var BOT_TOKEN:String = "YOUR_BOT_TOKEN";

	public static function main():Void {

		var botAPI:TelegramBotAPI = new TelegramBotAPI(BOT_TOKEN);
		botAPI.getMe(function(r:Response<User>) {
			if (r.ok) {
				trace(r.result);
			} else {
				trace('${r.error_code}: ${r.description}');
			}
		});
		
		MainLoop.addThread(keep);
	}

	private static function keep():Void while (true) Sys.sleep(1);

}