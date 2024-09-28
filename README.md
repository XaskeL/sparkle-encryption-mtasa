# sparkle-encryption-mtasa
### Описание
Крайне простая реализация шифрования для любых ваших файлов. Выкладываю, ибо проект для которого это было сделано - закрылся и работа была распорстранена на просторах MTA без указания автора.

### Особенности
Ресурс сам определяет автоматически, какие файлы не были зашифрованы и уведомляет об этом в консоли сервера, после шифрует файлы и меняет им расширение с *.dff на *.dffrw (чтобы избежать ошибок contains error при проверке ресурсов MTA-сервером).

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

`FxhnkW|IsqXBuNLT` это ключ, который хранит заголовок и информацию о зашифрованном файле внутри самого файла, в зашифрованном виде.
