# telegram-bot-api-hx
## Haxe Telegram Bot API
 - Automatically extracts [Telegram BotAPI](https://core.telegram.org/bots/api)
 - Currenlty provides full type support.
 - String enums in the next update.
## Example
```haxe
var botAPI:TelegramBotAPI = new TelegramBotAPI(BOT_TOKEN);
botAPI.getMe(function(r:Response<User>) {
	if (r.ok) {
		trace(r.result);
	} else {
		trace('${r.error_code}: ${r.description}');
	}
});
```