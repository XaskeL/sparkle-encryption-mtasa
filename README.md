# sparkle-encryption-mtasa
### Описание
Крайне простая реализация шифрования для любых ваших файлов. Выкладываю, ибо проект для которого это было сделано - закрылся и работа была распорстранена на просторах MTA без указания автора.

### Особенности
Ресурс самостоятельно автоматически определяет, какие файлы не были зашифрованы и уведомляет об этом в консоли сервера, после шифрует файлы и меняет им расширение с *.dff на *.dffrw (чтобы избежать ошибок contains error при проверке ресурсов MTA-сервером).

### Важно
**Не забудьте** поменять ключи на свои (минимум и не более 16-ти символов) в функциях:

```
function fileGetPrivateBuffer( path, key )
	-- ...
	
	local size, iv = tonumber( headData [ 1 ] ), teaDecode( headData [ 2 ], "FxhnkW|IsqXBuNLT"  ) -- МЕНЯТЬ ЗДЕСЬ
	
	-- ...
	
	return buffer
end
```

```
function fileSetPrivate( path, key )
	-- ...
	
	fileWrite( file, ("0x%x,%s\n"):format( size, teaEncode( iv, "FxhnkW|IsqXBuNLT" ) ), buffer ) -- МЕНЯТЬ ЗДЕСЬ
	
	-- ...
end
```

```
local headerKey = "vf@kk0qyFM8chUze" -- Находится в dynamic и EasyEmbed
```

`FxhnkW|IsqXBuNLT` (или `vf@kk0qyFM8chUze`) это ключ, который хранит заголовок и информацию о зашифрованном файле внутри самого файла, в зашифрованном виде.

### Поддержка автора

Для приобретения дополнений и/или улучшений, Вы можете обратиться по контактам доступным в моём профиле GitHub.

В данный момент имеется улучшение для `dynamic` загрузчика, а именно: загрузка моделей только если они находятся рядом с вами и видны на экране.

Так же в продаже интеграция данного шифрования дла защиты ваших интерфейсов и картинок.
