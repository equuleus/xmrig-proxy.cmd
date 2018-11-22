@ECHO OFF
REM RUN EXAMPLES:
REM	xmrig-proxy.cmd
REM	xmrig-proxy.cmd --action=<start/restart/stop> --proxy=<proxy_name> --coin=<coin_name> --elevate=<true/false>
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
TITLE XMRig Proxy

REM Задаем текущий путь, имя файла и расширение для файла конфигурации:
SET VARIABLE[CONFIG][FILEPATH]=%~dp0
REM Удаляем последний символ "\" из пути:
SET VARIABLE[CONFIG][FILEPATH]=%VARIABLE[CONFIG][FILEPATH]:~0,-1%
REM Имя файла конфигурации совпадает с именем скрипта:
SET VARIABLE[CONFIG][FILENAME]=%~n0
SET VARIABLE[CONFIG][EXTENSION]=cfg
REM Задачем символ, начало которого в файле конфигурации будет означать комментарий:
SET VARIABLE[CONFIG][COMMENT]=#
REM Получаем параметры коммандной строки:
SET VARIABLE[INPUT][PARAMETERS]=%*

REM ===========================================================================
REM ===========================================================================
ECHO.
REM Проверяем доступность файла конфигурации:
IF EXIST "%VARIABLE[CONFIG][FILEPATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%" (
REM Загружаем данные конфигурации:
	FOR /F "usebackq" %%A IN ("%VARIABLE[CONFIG][FILEPATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%") DO (
		SET VARIABLE[CONFIG][TEMP]=%%A
REM Если строка в файле конфигурации не пустая...
		IF "!VARIABLE[CONFIG][TEMP]!" NEQ "" (
REM Проверяем начало строки, - если она начинается с "#", то не загружаем строку как параметр конфигурации (считаем за комментарий):
			IF "!VARIABLE[CONFIG][TEMP]:~0,1!" NEQ "%VARIABLE[CONFIG][COMMENT]%" (
REM Все остальное задаем как параметры переменных и их значения:
				CALL SET %%A
			)
		)
		SET VARIABLE[CONFIG][TEMP]=
	)
REM Проверка на необходимость очистки лог-файла при старте (если задан и уже существует):
	IF /I "!SETTINGS[DEFAULT][LOG_CLEAR_ON_START]!" EQU "TRUE" CALL :LOG "CLEAR"
	CALL :LOG "[STATUS][INFO]	Starting..."
	IF "%VARIABLE[INPUT][PARAMETERS]%" NEQ "" CALL :LOG "[STATUS][INFO]	Input command parameters: '%VARIABLE[INPUT][PARAMETERS]%'."
REM Сохраняем исходное значение параметров командной строки:
	SET VARIABLE[INPUT][BACKUP]=%VARIABLE[INPUT][PARAMETERS]%
REM Получаем параметры коммандной строки (разбираем на значения):
	CALL :INPUT_PARAMETERS
REM Восстанавливаем исходное значение параметров командной строки:
	SET VARIABLE[INPUT][PARAMETERS]=!VARIABLE[INPUT][BACKUP]!
	SET VARIABLE[INPUT][BACKUP]=
REM Проверки на существование файлов по указанному пути в конфигурации:
	CALL :CHECK_FILE_EXIST
REM Проверяем доступность исполняемого файла:
	IF EXIST "!SETTINGS[PROGRAM][XMRIG][FILEPATH]!\!SETTINGS[PROGRAM][XMRIG][FILENAME]!" (
REM Задаем возможные значения для дейтсвия:
		SET SETTINGS[ACTION][1][NAME]=START
		SET SETTINGS[ACTION][2][NAME]=RESTART
		SET SETTINGS[ACTION][3][NAME]=STOP
REM Создаем список полученных данных по прокси/пулам:
		CALL :CONFIG_LIST_MAIN
REM Переход к основному блоку:
		GOTO MAIN
	) ELSE (
		CALL :LOG "[CONFIG][ERROR][CRITICAL]	Program file ^(""!SETTINGS[PROGRAM][XMRIG][FILEPATH]!\!SETTINGS[PROGRAM][XMRIG][FILENAME]!""^) not found."
		CALL :LOG "[STATUS][INFO]	Finish."
	)
) ELSE (
	CALL :LOG "[CONFIG][ERROR][CRITICAL]	Configuration file ^(""%VARIABLE[CONFIG][FILEPATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%""^) not found."
	CALL :LOG "[STATUS][INFO]	Finish."
)
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция получения параметров коммандной строки:
:INPUT_PARAMETERS
REM Перебираем в цикле все значения через пробел:
	FOR /F "tokens=1*" %%A IN ("%VARIABLE[INPUT][PARAMETERS]%") DO (
REM Присваиваем временной переменной текущее значение:
		SET VARIABLE[INPUT][TEMP]=%%A
REM Проверяем на совпадение начало строки параметра, если совпадение найдено, то присваиваем значение:
		IF /I "!VARIABLE[INPUT][TEMP]:~0,9!" EQU "--action=" SET VARIABLE[INPUT][ACTION]=!VARIABLE[INPUT][TEMP]:~9!
		IF /I "!VARIABLE[INPUT][TEMP]:~0,8!" EQU "--proxy=" SET VARIABLE[INPUT][PROXY]=!VARIABLE[INPUT][TEMP]:~8!
		IF /I "!VARIABLE[INPUT][TEMP]:~0,7!" EQU "--coin=" SET VARIABLE[INPUT][COIN]=!VARIABLE[INPUT][TEMP]:~7!
		IF /I "!VARIABLE[INPUT][TEMP]:~0,10!" EQU "--elevate=" SET VARIABLE[INPUT][ELEVATE]=!VARIABLE[INPUT][TEMP]:~10!
		SET VARIABLE[INPUT][TEMP]=
REM Если в строке еще что-то есть, повторяем цикл:
		IF "%%B" NEQ "" (
			SET VARIABLE[INPUT][PARAMETERS]=%%B
rem			CALL :INPUT_PARAMETERS
			GOTO INPUT_PARAMETERS
		)
	)
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция проверки нахождения путей и имен файлов в конфигурации:
:CHECK_FILE_EXIST
	FOR %%X IN (XMRIG, CSCRIPT, NETSTAT, TASKLIST, TASKKILL, TIMEOUT) DO (
		IF "!SETTINGS[PROGRAM][%%X][FILEPATH]!" NEQ "" (
			IF "!SETTINGS[PROGRAM][%%X][FILENAME]!" NEQ "" (
				IF EXIST "!SETTINGS[PROGRAM][%%X][FILEPATH]!\!SETTINGS[PROGRAM][%%X][FILENAME]!" (
					CALL :LOG "[CONFIG][INFO]	Path and filename for ""%%X"" successfully tested."
					CALL SET SETTINGS[PROGRAM][%%X]=!SETTINGS[PROGRAM][%%X][FILEPATH]!\!SETTINGS[PROGRAM][%%X][FILENAME]!
				) ELSE (
					CALL :LOG "[CONFIG][ERROR]	Path and filename for ""%%X"" not found at ""!SETTINGS[PROGRAM][%%X][FILEPATH]!\!SETTINGS[PROGRAM][%%X][FILENAME]!""."
				)
			) ELSE (
				CALL :LOG "[CONFIG][ERROR]	Filename for ""%%X"" is empty."
			)
		) ELSE (
			CALL :LOG "[CONFIG][ERROR]	Path for ""%%X"" is empty."
		)
	)
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция вывода на экран массива (списка) имен из всех указанных в конфигурации значений по прокси/пулам и сбора данных по монетам в конфигурации:
:CONFIG_LIST_MAIN
REM Определяем будущий массив со списком монет:
	SET VARIABLE[CONFIG][COIN_LIST]=
REM Разбираем все записи по прокси и пулам:
	FOR %%X IN (PROXY, POOL) DO (
		SET VARIABLE[CONFIG][LIST][TYPE]=%%X
REM Общее количество найденных записей:
		SET VARIABLE[CONFIG][LIST][TOTAL]=0
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
		SET /A VARIABLE[CONFIG][LIST][COUNT]=1
REM Цикл по нахождению всех записей в конфигурации:
		CALL :CONFIG_LIST_ALL
REM Выводим итоговую информацию по количеству:
		IF !VARIABLE[CONFIG][LIST][TOTAL]! EQU 0 (
			CALL :LOG "[CONFIG][ERROR]	No one !VARIABLE[CONFIG][LIST][TYPE]! found in configuration."
		) ELSE (
			CALL :LOG "[CONFIG][INFO]	Total !VARIABLE[CONFIG][LIST][TYPE]! found in configuration: !VARIABLE[CONFIG][LIST][TOTAL]!"
		)
		SET VARIABLE[CONFIG][LIST][COUNT]=
		SET VARIABLE[CONFIG][LIST][TOTAL]=
		SET VARIABLE[CONFIG][LIST][TYPE]=
	)
GOTO END
REM Функция циклического перебора всех значений, полученных из файла конфигурации по прокси/пулам:
:CONFIG_LIST_ALL
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[!VARIABLE[CONFIG][LIST][TYPE]!][!VARIABLE[CONFIG][LIST][COUNT]!][NAME] (
		IF !VARIABLE[CONFIG][LIST][COUNT]! EQU 1 (
			CALL :LOG "[CONFIG][INFO]	Loading !VARIABLE[CONFIG][LIST][TYPE]! data..."
		)
REM Если значение есть, выводим информацию и присваиваем его переменной:
		IF "!VARIABLE[CONFIG][LIST][TYPE]!" EQU "PROXY" (
			CALL :LOG "[CONFIG][INFO]		Found proxy: ""%%SETTINGS[!VARIABLE[CONFIG][LIST][TYPE]!][!VARIABLE[CONFIG][LIST][COUNT]!][NAME]%%"" ^(""%%SETTINGS[!VARIABLE[CONFIG][LIST][TYPE]!][!VARIABLE[CONFIG][LIST][COUNT]!][ADDRESS]%%:%%SETTINGS[!VARIABLE[CONFIG][LIST][TYPE]!][!VARIABLE[CONFIG][LIST][COUNT]!][PORT]%%""^)"
		)
		IF "!VARIABLE[CONFIG][LIST][TYPE]!" EQU "POOL" (
			CALL :LOG "[CONFIG][INFO]		Found pool for coin: ""%%SETTINGS[POOL][!VARIABLE[CONFIG][LIST][COUNT]!][COIN]%%"" ^(NAME: ""%%SETTINGS[POOL][!VARIABLE[CONFIG][LIST][COUNT]!][NAME]%%""^)"
REM Определяем стартовое значение счетчика для монет:
			SET /A VARIABLE[CONFIG][LIST][COIN][TOTAL]=1
REM Определяем значение для тестирования:
			CALL SET VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]=%%SETTINGS[!VARIABLE[CONFIG][LIST][TYPE]!][!VARIABLE[CONFIG][LIST][COUNT]!][COIN]%%
REM Дополнительно создаем спиок монет:
			CALL :CONFIG_LIST_COIN
REM Сбрасываем тестовое значение:
			SET VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]=
REM Сбрасываем счетчик:
			SET VARIABLE[CONFIG][LIST][COIN][TOTAL]=
		)
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[CONFIG][LIST][COUNT]=!VARIABLE[CONFIG][LIST][COUNT]! + 1
rem		CALL :CONFIG_LIST_ALL
		GOTO CONFIG_LIST_ALL
	) ELSE (
		SET /A VARIABLE[CONFIG][LIST][TOTAL]=!VARIABLE[CONFIG][LIST][COUNT]! - 1
	)
GOTO END
REM Функция поиска по массиву с добавлением в список значения монеты (если его там нет):
:CONFIG_LIST_COIN
REM Если массив еще не закончился (текущее порядковое значение имени читается):
	IF DEFINED SETTINGS[COIN][!VARIABLE[CONFIG][LIST][COIN][TOTAL]!][NAME] (
REM Задаем переменную с текущим значением имени из массива (по которому идем по списку от стартового значения до тех пор пока есть значения в массиве):
		CALL SET VARIABLE[CONFIG][LIST][COIN][COUNT]=%%SETTINGS[COIN][!VARIABLE[CONFIG][LIST][COIN][TOTAL]!][NAME]%%
REM Если заданная переменная имени текущего значения массива не совпадает с тестовым значением, то повторяем цикл, увеличивая счетчик и удаляя текущее значение (нам нужно пройти весь цикл и либо найти совпадение, тогда выход, так как добавлять уже нечего, либо в самом конце, если не находим, добавляем тестовое значение):
		IF "!VARIABLE[CONFIG][LIST][COIN][COUNT]!" NEQ "!VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]!" (
			SET /A VARIABLE[CONFIG][LIST][COIN][TOTAL]=!VARIABLE[CONFIG][LIST][COIN][TOTAL]! + 1
			SET VARIABLE[CONFIG][LIST][COIN][COUNT]=
rem			CALL :CONFIG_LIST_COIN
			GOTO CONFIG_LIST_COIN
REM Если заданная переменная текущего значения массива совпадает с тестовым значением, то выходим из функции, ничего не делая (тестовое значение уже есть в массиве):
		) ELSE (
			SET VARIABLE[CONFIG][LIST][COIN][COUNT]=
		)
REM Если значение имени в массиве с текущим счетчиком не удалось прочитать, значит массив закончился, а искомого тестового значения мы так и не нашли:
	) ELSE (
REM Добавляем тестовое значение в массив:
		CALL SET SETTINGS[COIN][!VARIABLE[CONFIG][LIST][COIN][TOTAL]!][NAME]=!VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]!
	)
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Основная функция проверки и формирования параметров запуска программы:
:MAIN
REM Проверяем текущие права:
	NET SESSION >NUL 2>&1
REM Если это запуск скрипта без повышенных прав:
	IF "%ERRORLEVEL%" EQU "0" (
		SET VARIABLE[VALUE][ELEVATE]=TRUE
		CALL :LOG "[STATUS][INFO]	Running with elevated priveleges."
	) ELSE (
		SET VARIABLE[VALUE][ELEVATE]=FALSE
		CALL :LOG "[STATUS][INFO]	Running with normal priveleges."
	)
REM Получаем проверенные значения выбора:
	FOR %%X IN (ACTION, PROXY, COIN) DO (
		CALL :CHECK_INPUT_MAIN %%X
		CALL SET VARIABLE[VALUE][%%X]=!VARIABLE[CHECK][VALUE]!
		SET VARIABLE[CHECK][VALUE]=
	)
REM Если в параметрах запуска указано запускаться с повышенными правами:
	IF /I "%VARIABLE[INPUT][ELEVATE]%" EQU "TRUE" (
		IF EXIST "%SETTINGS[PROGRAM][CSCRIPT]%" (
REM Формируем новую строку с полученными и проверенными параметрами запуска скрипта:
			FOR %%X IN (ACTION, PROXY, COIN) DO (
				IF "!VARIABLE[VALUE][%%X]!" NEQ "" SET VARIABLE[INPUT][LIST]=!VARIABLE[INPUT][LIST]! --%%X=!VARIABLE[VALUE][%%X]!
			)
REM Удаляем первый символ в сформированной строчке:
			SET VARIABLE[INPUT][LIST]=!VARIABLE[INPUT][LIST]:~1!
REM Добавляем параметр запрещающий повышение прав (чтобы не получилось рекурсии):
			SET VARIABLE[INPUT][LIST]=!VARIABLE[INPUT][LIST]! --ELEVATE=FALSE
REM Вызываем VBS-скрипт повышения прав:
			CALL :LOG "[STATUS][INFO]	Trying to elevate priveleges..."
rem			CALL :ELEVATE
			GOTO :ELEVATE
		) ELSE (
			CALL :LOG "[CONFIG][ERROR]	CSCRIPT file ^(""!SETTINGS[PROGRAM][CSCRIPT]!""^) not found. Can not elevate priveleges."
		)
	)
REM Формируем строку параметров для запуска программы:
	CALL :PARAMETERS_MAIN
REM Если параметры для запуска получены, переходим к процессу действия:
	IF "%VARIABLE[PROGRAM][PARAMETERS][XMRIG]%" NEQ "" (
		IF "%VARIABLE[VALUE][ACTION]%" NEQ "" (
rem			CALL :ACTION_MAIN
			GOTO ACTION_MAIN
		) ELSE (
			CALL :LOG "[INPUT][ERROR]	Action is not set. Nothing to do."
			CALL :LOG "[STATUS][INFO]	Finish."
		)
	) ELSE (
		CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not generate program parameters. Can not continue."
		CALL :LOG "[STATUS][INFO]	Finish."
	)
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция проверки выбора ввода:
:CHECK_INPUT_MAIN
REM Определяем стартовые значения счетчиков [счетчик количества проходов в цикле и счетчик положения в массиве] (если это первый проход и оно не задано), задаем тип поиска и искомое значение:
	IF NOT DEFINED VARIABLE[CHECK][RETRY] SET /A VARIABLE[CHECK][RETRY]=1
	IF NOT DEFINED VARIABLE[CHECK][COUNT] (
		SET /A VARIABLE[CHECK][COUNT]=1
REM Проверяем параметр запуска функции и задаем необходимые переменные (если они не получены ранее):
		SET VARIABLE[CHECK][TYPE]=%~1
		CALL SET VARIABLE[CHECK][VALUE_TEST]=%%VARIABLE[INPUT][!VARIABLE[CHECK][TYPE]!]%%
	)
REM Если получено какое-то значение...
	IF "%VARIABLE[CHECK][VALUE_TEST]%" NEQ "" (
REM Задаем текущее значение в зависимости от типа вызова:
		SET VARIABLE[CHECK][VALUE_CURRENT]=!SETTINGS[%VARIABLE[CHECK][TYPE]%][%VARIABLE[CHECK][COUNT]%][NAME]!
REM Если значение есть, - проверяем дальше:
		IF "!VARIABLE[CHECK][VALUE_CURRENT]!" NEQ "" (
REM Проверяем на свопадение текущего значения из массива и ранее заданного искомого:
			IF /I "!VARIABLE[CHECK][VALUE_CURRENT]!" EQU "%VARIABLE[CHECK][VALUE_TEST]%" (
REM Извещаем об успешном нахождении:
				CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
				CALL :LOG "[STATUS][INFO]	Selected ""!VARIABLE[CHECK][VALUE_CURRENT]!"" !VARIABLE[LOWERCASE][VALUE]!."
				SET VARIABLE[LOWERCASE][VALUE]=
REM Задаем искомое значение, завершаем:
				SET VARIABLE[CHECK][VALUE]=!VARIABLE[CHECK][VALUE_CURRENT]!
				SET VARIABLE[CHECK][VALUE_CURRENT]=
			) ELSE (
REM Увеличиваем значение счетчика положения в массиве и переходим в начало цикла:
				SET /A VARIABLE[CHECK][COUNT]=%VARIABLE[CHECK][COUNT]% + 1
				SET VARIABLE[CHECK][VALUE_CURRENT]=
				GOTO CHECK_INPUT_MAIN
			)
REM Если прошли весь массив значений монет, а выбранной записи так и не обнаружено, то повторно пробуем задать значение или берем его из параметра по умолчанию:
		) ELSE (
REM Если задана возможность ручного ввода данных:
			IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%" EQU "TRUE" (
				CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
				CALL :LOG "[INPUT][ERROR]	Selected ""%VARIABLE[CHECK][VALUE_TEST]%"" is not correct !VARIABLE[LOWERCASE][VALUE]!. Please, try again..."
REM Сбрасываем неправильное значение:
				SET VARIABLE[CHECK][VALUE_TEST]=
rem				CALL :CHECK_INPUT_SELECT
				GOTO CHECK_INPUT_SELECT
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию и выходим:
			) ELSE (
				CALL :CHECK_INPUT_AUTOMATIC_TEST
			)
		)
REM Если значение не задано:
	) ELSE (
REM Если задана возможность ручного ввода данных:
		IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%" EQU "TRUE" (
			CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
REM Если это не первый проход цикла и ввод пустой, предлагаем ввести значение по умолчанию:
			IF %VARIABLE[CHECK][RETRY]% GTR 1 (
				CALL :TIMESTAMP
REM Получаем значение из консоли:
				IF "%VARIABLE[CHECK][DEFAULT]%" EQU "" (
					CALL SET /P VARIABLE[CHECK][DEFAULT]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	You choice is empty. Use dafault !VARIABLE[LOWERCASE][VALUE]! value ^(%%SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]%%^) [Y/N]: "
				) ELSE (
					SET VARIABLE[CHECK][DEFAULT]=
					CALL SET /P VARIABLE[CHECK][DEFAULT]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Incorrect. Please use only "Y" or "N". Use dafault !VARIABLE[LOWERCASE][VALUE]! value ^(%%SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]%%^) [Y/N]: "
				)
				IF /I "!VARIABLE[CHECK][DEFAULT]!" EQU "Y" (
REM Если ответ положительный, запоминаем значение и возвращаемся для проверки:
					CALL SET VARIABLE[CHECK][VALUE_TEST]=%%SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]%%
					SET VARIABLE[CHECK][DEFAULT]=
					GOTO CHECK_INPUT_MAIN
				) ELSE (
					IF /I "!VARIABLE[CHECK][DEFAULT]!" EQU "N" (
						SET VARIABLE[CHECK][DEFAULT]=
					) ELSE (
						GOTO CHECK_INPUT_MAIN
					)
				)
			)
rem			CALL :CHECK_INPUT_SELECT
			GOTO CHECK_INPUT_SELECT
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию и выходим:
		) ELSE (
			CALL :CHECK_INPUT_AUTOMATIC_TEST
		)
	)
REM Очищаем значения:
	SET VARIABLE[CHECK][VALUE_TEST]=
	SET VARIABLE[CHECK][TYPE]=
	SET VARIABLE[CHECK][COUNT]=
	SET VARIABLE[CHECK][RETRY]=
GOTO END
:CHECK_INPUT_SELECT
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
	CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
	CALL :TIMESTAMP
REM Получаем значение из консоли:
	SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a !VARIABLE[LOWERCASE][VALUE]! (<ENTER> for default value) !VARIABLE[VALUE][INPUT][SELECT]!: "
	SET VARIABLE[LOWERCASE][VALUE]=
REM Увеличиваем счетчик проходов:
	SET /A VARIABLE[CHECK][RETRY]=%VARIABLE[CHECK][RETRY]% + 1
REM Сбрасываем счетчик положения в массиве в начальное положение:
	SET /A VARIABLE[CHECK][COUNT]=1
REM Снова проходим тестирование на совпадение:
	GOTO CHECK_INPUT_MAIN
GOTO END
:CHECK_INPUT_AUTOMATIC_TEST
REM Если это первый проход цикла, то пробуем задать значение по умолчанию из файла конфигурации:
	IF "%VARIABLE[CHECK][RETRY]%" EQU "1" (
REM Задаем значение для тестирования:
		SET VARIABLE[CHECK][VALUE_TEST]=!SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]!
REM Выводим сообщение:
		CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
		CALL :LOG "[STATUS][ERROR]	Input value not found. Default value ^(""--!VARIABLE[LOWERCASE][VALUE]!=!SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]!""^) was set."
		SET VARIABLE[LOWERCASE][VALUE]=
REM Увеличиваем счетчик проходов:
		SET /A VARIABLE[CHECK][RETRY]=%VARIABLE[CHECK][RETRY]% + 1
		GOTO CHECK_INPUT_MAIN
REM Если это последующие проходы цикла, значит значение по умолчанию указанное в конфигурации не совпадает с доступными в этой же конфигурации значениями:
	) ELSE (
		CALL :LOG "[CONFIG][ERROR][CRITICAL] Default value ^(""--!VARIABLE[LOWERCASE][VALUE]!=!SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]!""^) does not match with configuration set."
		CALL :LOG "[STATUS][INFO]	Finish."
		EXIT
	)
GOTO END
REM Функция формирования текста для подсказки выбора:
:CHECK_INPUT_TEXT_FORMAT
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано), обнуляем на всякий случай значение результата и задаем тип поиска:
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT] (
		SET /A VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=1
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=%~1
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=
		SET VARIABLE[VALUE][INPUT][SELECT]=
	)
REM Проверяем, задано ли значение NAME. Если значение есть, добавляем его в общий список:
	IF DEFINED SETTINGS[!VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]!][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME] (
REM В зависимости от того какой проход цикла:
		IF %VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]% EQU 1 (
REM Задаем начальное значение текста:
			CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=[
		) ELSE (
REM Если это последующие проходы цикла, то ставим разделитель "/":
			CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=!VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]! /
		)
REM Добавляем к концу строки переменной найденное значение:
		CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=!VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]! %%SETTINGS[!VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]!][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME]%%
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=!VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]! + 1
		GOTO CHECK_INPUT_TEXT_FORMAT
	) ELSE (
		IF "!VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!" NEQ "" (
REM Задаем окончательное значение текста:
			SET VARIABLE[VALUE][INPUT][SELECT]=!VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]! ]
			SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=
		)
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=
	)
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция создания параметров коммандной строки для запуска программы:
:PARAMETERS_MAIN
REM Получаем параметры строки запуска для прокси:
	CALL :PARAMETERS_PROXY_GET
	CALL :PARAMETERS_PROXY_TO_STRING
REM Если полученная строка параметров прокси пустая, то выходим:
	IF "%VARIABLE[PROGRAM][PARAMETERS][PROXY]%" EQU "" GOTO END
REM Получаем параметры строки запуска для пула:
	CALL :PARAMETERS_POOL_GET
	CALL :PARAMETERS_POOL_TO_STRING
REM Если полученная строка параметров пулов пустая, то выходим:
	IF "%VARIABLE[PROGRAM][PARAMETERS][POOLS]%" EQU "" GOTO END
REM Добавляем в строку параметров для программы полученные данные по прокси и пулам:
	SET VARIABLE[PROGRAM][PARAMETERS][XMRIG]=%VARIABLE[PROGRAM][PARAMETERS][PROXY]% !VARIABLE[PROGRAM][PARAMETERS][POOLS]!
REM Добавляем в строку параметров для программы данные по умолчанию, указанные в конфигурации (если там что-то есть):
	IF "%SETTINGS[PROGRAM][XMRIG][PARAMETERS]%" NEQ "" SET VARIABLE[PROGRAM][PARAMETERS][XMRIG]=!VARIABLE[PROGRAM][PARAMETERS][XMRIG]! %SETTINGS[PROGRAM][XMRIG][PARAMETERS]%
GOTO END
:PARAMETERS_PROXY_GET
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=1
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		SET VARIABLE[PARAMETERS][PROXY][CURRENT]=!SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NAME]!
		IF "!VARIABLE[PARAMETERS][PROXY][CURRENT]!" EQU "%VARIABLE[VALUE][PROXY]%" (
			FOR %%Y IN (NAME, ALGORYTM, ADDRESS, PORT, API, TOKEN, NO-RESTRICTED) DO (
				CALL SET VARIABLE[PARAMETERS][PROXY][%%Y]=!SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][%%Y]!
			)
			SET VARIABLE[PARAMETERS][PROXY][CURRENT]=
			SET VARIABLE[PARAMETERS][COUNT]=
		) ELSE (
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][PROXY][CURRENT]=
			GOTO PARAMETERS_PROXY_GET
		)
	) ELSE (
		SET VARIABLE[PARAMETERS][COUNT]=
	)
GOTO END
:PARAMETERS_PROXY_TO_STRING
REM Формируем строку параметров для программы по данным прокси из обязательных параметров (ALGORYTM, ADDRESS, PORT) и возможных (API, TOKEN):
	IF "%VARIABLE[PARAMETERS][PROXY][ALGORYTM]%" NEQ "" (
		IF "%VARIABLE[PARAMETERS][PROXY][ADDRESS]%" NEQ "" (
			IF "%VARIABLE[PARAMETERS][PROXY][PORT]%" NEQ "" (
				SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=--algo=%VARIABLE[PARAMETERS][PROXY][ALGORYTM]% --bind=%VARIABLE[PARAMETERS][PROXY][ADDRESS]%:%VARIABLE[PARAMETERS][PROXY][PORT]%
				IF "%VARIABLE[PARAMETERS][PROXY][API]%" NEQ "" (
					SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=!VARIABLE[PROGRAM][PARAMETERS][PROXY]! --api-port=%VARIABLE[PARAMETERS][PROXY][API]%
					IF "%VARIABLE[PARAMETERS][PROXY][TOKEN]%" NEQ "" (
						SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=!VARIABLE[PROGRAM][PARAMETERS][PROXY]! --api-access-token=%VARIABLE[PARAMETERS][PROXY][TOKEN]%
					)
				)
			) ELSE (
				CALL :PARAMETERS_PROXY_TO_STRING_ERROR PORT
			)
		) ELSE (
			CALL :PARAMETERS_PROXY_TO_STRING_ERROR ADDRESS
		)
	) ELSE (
		CALL :PARAMETERS_PROXY_TO_STRING_ERROR ALGORYTM
	)
	IF "%VARIABLE[PROGRAM][PARAMETERS][PROXY]%" NEQ "" (
		IF "%VARIABLE[PARAMETERS][PROXY][NO-RESTRICTED]%" EQU "TRUE" SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=%VARIABLE[PROGRAM][PARAMETERS][PROXY]% --api-no-restricted
	)
GOTO END
:PARAMETERS_PROXY_TO_STRING_ERROR
	CALL :LOG "[STATUS][ERROR][CRITICAL]	Parameter ""%~1"" in configuration was not set for proxy: ""%VARIABLE[PARAMETERS][PROXY][NAME]%"". Proxy will not be used."
	CALL :LOG "[STATUS][INFO]	Finish."
	EXIT
GOTO END
:PARAMETERS_POOL_GET
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=1
	IF NOT DEFINED VARIABLE[PARAMETERS][POOL][COUNT] SET /A VARIABLE[PARAMETERS][POOL][COUNT]=1
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=!SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][COIN]!
REM Если заданная монета пула совпадает с тем что мы перебираем из конфигурации...
		IF "!VARIABLE[PARAMETERS][POOL][CURRENT][COIN]!" EQU "%VARIABLE[VALUE][COIN]%" (
REM Получем значение алгоритма для текущего пула:
			SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=!SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][ALGORYTM]!
REM Проверяем, совпадают-ли алгоритмы с тем, который задан в прокси:
			IF /I "!VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]!" EQU "%VARIABLE[PARAMETERS][PROXY][ALGORYTM]%" (
REM Формируем новый список (массив) пулов, которые нам подходят для использования
				FOR %%Y IN (NAME, ALGORYTM, ADDRESS, PORT, DIFF, EMAIL, WALLET) DO (
					CALL SET VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][POOL][COUNT]!][%%Y]=!SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][%%Y]!
				)
REM Увеличиваем значения счетчиков (основного, по циклу, и второго - счетчик элементов в новом массиве) и переходим в начало цикла:
				SET /A VARIABLE[PARAMETERS][POOL][COUNT]=%VARIABLE[PARAMETERS][POOL][COUNT]% + 1
				SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=
			) ELSE (
				SET VARIABLE[PARAMETERS][POOL][CURRENT][NAME]=!SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME]!
				CALL :LOG "[STATUS][ERROR]	Found correct pool ^(""!VARIABLE[PARAMETERS][POOL][CURRENT][NAME]!""^) for ""%VARIABLE[VALUE][COIN]%"" coin, but algorytm with proxy ^(""%VARIABLE[PARAMETERS][PROXY][NAME]%""^) is different. Ignored."
				SET VARIABLE[PARAMETERS][POOL][CURRENT][NAME]=
				SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=
			)
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=
			GOTO PARAMETERS_POOL_GET
		) ELSE (
REM Если значения не совпадает, пропускаем данный пул, не добавляя его в новый массив, увеличиваем значение основного счетчика и переходим в начало цикла:
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=
			GOTO PARAMETERS_POOL_GET
		)
	) ELSE (
		SET VARIABLE[PARAMETERS][COUNT]=
	)
GOTO END
:PARAMETERS_POOL_TO_STRING
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=1
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		FOR %%Y IN (ADDRESS, PORT, DIFF, EMAIL, WALLET) DO (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][%%Y]=!VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][%%Y]!
		)
		IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][ADDRESS]!" NEQ "" (
			IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]!" NEQ "" (
				IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]!" NEQ "" (
					CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]=--url=!VARIABLE[PROGRAM][PARAMETERS][POOL][ADDRESS]!:!VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]! --user=!VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]!+!VARIABLE[PROGRAM][PARAMETERS][POOL][DIFF]! --pass=%VARIABLE[PARAMETERS][PROXY][NAME]%:!VARIABLE[PROGRAM][PARAMETERS][POOL][EMAIL]!
				) ELSE (
					CALL :PARAMETERS_POOL_TO_STRING_ERROR WALLET
				)
			) ELSE (
				CALL :PARAMETERS_POOL_TO_STRING_ERROR PORT
			)
		) ELSE (
			CALL :PARAMETERS_POOL_TO_STRING_ERROR ADDRESS
		)
		IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!" NEQ "" (
			IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOLS] (
				CALL SET VARIABLE[PROGRAM][PARAMETERS][POOLS]=!VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!
			) ELSE (
				CALL SET VARIABLE[PROGRAM][PARAMETERS][POOLS]=%VARIABLE[PROGRAM][PARAMETERS][POOLS]% !VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!
			)
			SET VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]=
		)
		FOR %%Y IN (URL, ADDRESS, PORT, DIFF, EMAIL, WALLET) DO (
			SET VARIABLE[PROGRAM][PARAMETERS][POOL][%%Y]=
		)
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
		GOTO PARAMETERS_POOL_TO_STRING
	) ELSE (
		SET VARIABLE[PARAMETERS][COUNT]=
	)
GOTO END
:PARAMETERS_POOL_TO_STRING_ERROR
	CALL :LOG "[STATUS][ERROR]	Parameter ""%~1"" in configuration was not set for pool: ""%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"". Pool will not be added to list."
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция проверки требуемого действия:
:ACTION_MAIN
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[ACTION][COUNT] SET /A VARIABLE[ACTION][COUNT]=1
REM Проверяем, доступен ли заданный в конфигурации файл "NETSTAT":
	IF EXIST "%SETTINGS[PROGRAM][NETSTAT]%" (
REM Ищем среди запущенных процессов нужный с данным портом:
		FOR /F "tokens=5" %%A IN ('%SETTINGS[PROGRAM][NETSTAT]% -a -n -o ^|FIND /I "LISTENING" ^|FIND "%VARIABLE[PARAMETERS][PROXY][PORT]%"') DO SET VARIABLE[PROGRAM][PID][NETSTAT]=%%A
REM Если в ответ по запросу нужного порта мы получили ответ с номером PID:
		IF "!VARIABLE[PROGRAM][PID][NETSTAT]!" NEQ "" (
REM Проверяем, доступен ли заданный в конфигурации файл "TASKLIST":
			IF EXIST "%SETTINGS[PROGRAM][TASKLIST]%" (
REM Пробуем проверить есть ли найденный PID с нужным именем процесса:
				FOR /F "tokens=2 delims=," %%A IN ('%SETTINGS[PROGRAM][TASKLIST]% /FI "IMAGENAME EQ %SETTINGS[PROGRAM][XMRIG][FILENAME]%" /FI "PID EQ !VARIABLE[PROGRAM][PID][NETSTAT]!" /FO:CSV /NH^| FIND /I "!VARIABLE[PROGRAM][PID][NETSTAT]!"') DO SET VARIABLE[PROGRAM][PID][TASKLIST]=%%~A
REM Если процесс найден:
				IF "!VARIABLE[PROGRAM][PID][TASKLIST]!" NEQ "" (
					IF /I "%VARIABLE[VALUE][ACTION]%" EQU "START" (
						CALL :LOG "[STATUS][INFO]	Proxy already started ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Nothing to do."
						SET VARIABLE[ACTION][COUNT]=
						CALL :LOG "[STATUS][INFO]	Finish."
					) ELSE (
REM Проверяем, доступен ли заданный в конфигурации файл "TASKKILL":
						IF EXIST "%SETTINGS[PROGRAM][TASKKILL]%" (
							IF %VARIABLE[ACTION][COUNT]% EQU 1 (
								CALL :LOG "[STATUS][INFO]	Found started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Trying to stop it..."
							) ELSE (
								IF %VARIABLE[ACTION][COUNT]% GTR %SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]% (
									CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not stop already started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Maximum attempts ^(%SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]%^) reached while trying to stop a running process. Exiting."
									SET VARIABLE[ACTION][COUNT]=
									GOTO END
								) ELSE (
									CALL :LOG "[STATUS][ERROR]	Can not stop already started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^) for this instance. Retry attempt %VARIABLE[ACTION][COUNT]% of %SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]%..."
								)
							)
							IF /I "%VARIABLE[VALUE][ACTION]%" EQU "RESTART" (
								IF /I "%VARIABLE[VALUE][ACTION][RESTART]%" EQU "TRUE" (
									SET VARIABLE[VALUE][ACTION][RESTART]=
									CALL :LOG "[STATUS][INFO]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" was restarted."
									SET VARIABLE[ACTION][COUNT]=
									CALL :LOG "[STATUS][INFO]	Finish."
									GOTO END
								) ELSE (
									SET VARIABLE[VALUE][ACTION][RESTART]=FALSE
								)
							)
							IF /I "%VARIABLE[VALUE][ACTION]%" EQU "STOP" SET VARIABLE[VALUE][ACTION][STOP]=FALSE
							CALL :ACTION_STOP
							SET VARIABLE[PROGRAM][PID][TASKLIST]=
							SET VARIABLE[PROGRAM][PID][NETSTAT]=
							SET /A VARIABLE[ACTION][COUNT]=%VARIABLE[ACTION][COUNT]% + 1
							CALL :TIMEWAIT 1
							GOTO ACTION_MAIN
						) ELSE (
							CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not stop process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^), because ""TASKKILL"" file not found at ""%SETTINGS[PROGRAM][TASKKILL][FILEPATH]%\%SETTINGS[PROGRAM][TASKKILL][FILENAME]%"". Please close and stop process manually."
							CALL :LOG "[STATUS][INFO]	Finish."
							SET VARIABLE[ACTION][COUNT]=
						)
					)
				) ELSE (
					CALL :LOG "[STATUS][ERROR][CRITICAL]	Requested port ""!VARIABLE[PROGRAM][PID][NETSTAT]!"" is busy by another process. Please release port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" manually before start a program. Can not continue."
					CALL :LOG "[STATUS][INFO]	Finish."
					SET VARIABLE[ACTION][COUNT]=
				)
			) ELSE (
				CALL :LOG "[STATUS][ERROR][CRITICAL]	Requested port is busy by PID ""!VARIABLE[PROGRAM][PID][NETSTAT]!"", but can not check wich process is running on it, because ""TASKLIST"" file not found at ""%SETTINGS[PROGRAM][TASKLIST][FILEPATH]%\%SETTINGS[PROGRAM][TASKLIST][FILENAME]%"". Please release port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" manually before start a program. Can not continue."
				CALL :LOG "[STATUS][INFO]	Finish."
				SET VARIABLE[ACTION][COUNT]=
			)
		) ELSE (
			IF /I "%VARIABLE[VALUE][ACTION]%" EQU "START" (
				CALL :LOG "[STATUS][INFO]	Trying to start a program..."
				SET VARIABLE[ACTION][COUNT]=
				GOTO ACTION_START
			) ELSE (
				IF /I "%VARIABLE[VALUE][ACTION]%" EQU "RESTART" (
					IF /I "%VARIABLE[VALUE][ACTION][RESTART]%" EQU "" (
						IF "%VARIABLE[INPUT][TEMP]%" EQU "" (
							CALL :LOG "[STATUS][ERROR]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" is not running (port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" not found in a process list), can not restart it."
							CALL :TIMESTAMP
REM Получаем значение из консоли:
							CALL SET /P VARIABLE[INPUT][TEMP]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Change action to "START" and start a program [Y/N]: "
						) ELSE (
							CALL :TIMESTAMP
REM Получаем значение из консоли:
							CALL SET /P VARIABLE[INPUT][TEMP]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Incorrect. Please use only "Y" or "N". Change action to "START" and start a program [Y/N]: "
						)
						IF /I "!VARIABLE[INPUT][TEMP]!" EQU "Y" (
							SET VARIABLE[INPUT][TEMP]=
							CALL :LOG "[STATUS][INFO]	Changing action to ""START""..."
							SET VARIABLE[VALUE][ACTION]=START
							GOTO ACTION_MAIN
						) ELSE (
							IF /I "!VARIABLE[INPUT][TEMP]!" EQU "N" (
								SET VARIABLE[INPUT][TEMP]=
								CALL :LOG "[STATUS][INFO]	Finish."
								SET VARIABLE[ACTION][COUNT]=
							) ELSE (
								GOTO ACTION_MAIN
							)
						)
					) ELSE (
						IF /I "%VARIABLE[VALUE][ACTION][RESTART]%" EQU "FALSE" (
							SET VARIABLE[VALUE][ACTION][RESTART]=TRUE
							CALL :LOG "[STATUS][INFO]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" was stopped. Starting..."
							SET VARIABLE[ACTION][COUNT]=
							GOTO ACTION_START
						) ELSE (
							CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not stop already started process of proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" for restarting."
							CALL :LOG "[STATUS][INFO]	Finish."
							SET VARIABLE[ACTION][COUNT]=
						)
					)
				)
				IF /I "%VARIABLE[VALUE][ACTION]%" EQU "STOP" (
					IF /I "%VARIABLE[VALUE][ACTION][STOP]%" EQU "FALSE" (
						CALL :LOG "[STATUS][INFO]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" was stopped."
						SET VARIABLE[VALUE][ACTION][STOP]=
						CALL :LOG "[STATUS][INFO]	Finish."
						SET VARIABLE[ACTION][COUNT]=
					) ELSE (
						CALL :LOG "[STATUS][INFO]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" not found in running processes."
						CALL :LOG "[STATUS][INFO]	Finish."
						SET VARIABLE[ACTION][COUNT]=
					)
				)
			)
		)
	) ELSE (
		CALL :LOG "[STATUS][ERROR]	Can not check requested port (is it busy or not) before start a program, because ""NETSTAT"" file not found at ""%SETTINGS[PROGRAM][NETSTAT][FILEPATH]%\%SETTINGS[PROGRAM][NETSTAT][FILENAME]%""."
		IF /I "%VARIABLE[VALUE][ACTION]%" EQU "START" (
			IF /I "%SETTINGS[DEFAULT][ALLOW_START_WITHOUT_PID_CHECK]%" EQU "TRUE" (
				CALL :LOG "[STATUS][INFO]	Found positive flag (""ALLOW_START_WITHOUT_PID_CHECK"" is set to ""TRUE"") in configuration to start a program."
				SET VARIABLE[ACTION][COUNT]=
				GOTO ACTION_START
			) ELSE (
				CALL :LOG "[STATUS][INFO]	Finish."
				SET VARIABLE[ACTION][COUNT]=
			)
		) ELSE (
			CALL :LOG "[STATUS][INFO]	Finish."
			SET VARIABLE[ACTION][COUNT]=
		)
	)
GOTO END
:ACTION_START
	CD "%SETTINGS[PROGRAM][XMRIG][FILEPATH]%"
REM В заивисимости от того задано ли повышение прав до уровня Администратора или нет, запускаем программу разными методами (в отлельном окне, или в том же самом):
	IF /I "%VARIABLE[VALUE][ELEVATE]%" EQU "TRUE" (
		CALL :LOG "[STATUS][INFO]	Starting: '%SETTINGS[PROGRAM][XMRIG][FILEPATH]%\%SETTINGS[PROGRAM][XMRIG][FILENAME]%' %VARIABLE[PROGRAM][PARAMETERS][XMRIG]%"
		CLS
		CALL "%SETTINGS[PROGRAM][XMRIG][FILEPATH]%\%SETTINGS[PROGRAM][XMRIG][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS][XMRIG]%
	) ELSE (
		CALL :LOG "[STATUS][INFO]	Starting: START '%SETTINGS[PROGRAM][TITLE]%' /D '%SETTINGS[PROGRAM][XMRIG][FILEPATH]%' '%SETTINGS[PROGRAM][XMRIG][FILENAME]%' %VARIABLE[PROGRAM][PARAMETERS][XMRIG]%"
		START "%SETTINGS[PROGRAM][TITLE]%" /D "%SETTINGS[PROGRAM][XMRIG][FILEPATH]%" "%SETTINGS[PROGRAM][XMRIG][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS][XMRIG]%
		CALL :LOG "[STATUS][INFO]	Finish."
	)
GOTO END
:ACTION_STOP
	%SETTINGS[PROGRAM][TASKKILL]% /F /PID %VARIABLE[PROGRAM][PID][TASKLIST]% >NUL
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция повышения прав через внутренний запуск VBS-скрипта:
:ELEVATE
REM Создаем скрипт-файл VBS со строкой запуска:
	CALL :LOG "[STATUS][INFO]	Creating new VBScript..."
	ECHO CreateObject^("Shell.Application"^).ShellExecute "%~snx0","!VARIABLE[INPUT][LIST]!","%~sdp0","runas","%SETTINGS[PROGRAM][TITLE]%">"%TEMP%\%~n0.vbs"
	CALL :LOG "[STATUS][INFO]	Starting new script (""%TEMP%\%~n0.vbs"") and closing parent..."
REM Запускаем созданный скрипт-файл:
	%SETTINGS[PROGRAM][CSCRIPT]% //nologo "%TEMP%\%~n0.vbs"
REM Удаляем созданный скрипт-файл:
	IF EXIST "%TEMP%\%~n0.vbs" DEL "%TEMP%\%~n0.vbs"
	CALL :LOG "[STATUS][INFO]	Finish."
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция ожидания запуска с определенным интервалом:
:TIMEWAIT
REM Проверяем задано ли значение временной задержки, если не задано, то используем значение по умолчанию:
	IF "%~1" NEQ "" (
		SET VARIABLE[TIMEWAIT][VALUE]=%~1
	) ELSE (
		SET VARIABLE[TIMEWAIT][VALUE]=%SETTINGS[DEFAULT][TIMEWAIT]%
	)
REM Если файл TIMEOUT задан и существует, запускаем через него:
	IF EXIST "%SETTINGS[PROGRAM][TIMEOUT]%" (
		%SETTINGS[PROGRAM][TIMEOUT]% /T %VARIABLE[TIMEWAIT][VALUE]% >NUL
REM Если файл не задан или не существует, то решаем задачу через встроенную возможность задать интервал в PING:
	) ELSE (
		PING 127.0.0.1 -n "%VARIABLE[TIMEWAIT][VALUE]%" >NUL
	)
REM Сбрасываем текущее значение:
	SET VARIABLE[TIMEWAIT][VALUE]=
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция получения штампа времени (текущее время в специальном формате):
:TIMESTAMP
REM Получаем текущее время через wMIC (медленнее, тормозит выполнение, по этому лучше не использовать!):
rem	FOR /F "tokens=2 delims==" %%A IN ('wMIC OS GET LocalDateTime /FORMAT:value^| FIND "="') DO SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]=%%A
REM Резервный вариант получения даты и времени:
	IF "%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]%" EQU "" (
rem		FOR /F "tokens=1-3 delims=/.- " %%A IN ("DATE /T") DO (
		FOR /F "tokens=1-3 delims=/.- " %%A IN ("%DATE%") DO (
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_DAY]=%%A
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MONTH]=%%B
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_YEAR]=%%C
		)
rem		FOR /F "tokens=1-2 delims=/:,- " %%A IN ("TIME /T") DO (
		FOR /F "tokens=1-3 delims=/:,- " %%A IN ("%TIME%") DO (
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_HOUR]=%%A
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MINUTE]=%%B
			SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_SECOND]=%%C
		)
	) ELSE (
REM Делим полученное значение по количеству символов:
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_DAY]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~6,2%
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MONTH]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~4,2%
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_YEAR]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~0,4%
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_HOUR]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~8,2%
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MINUTE]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~10,2%
		SET VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_SECOND]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT]:~12,2%
	)
REM Составляем нужный нам формат:
	SET VARIABLE[TIMESTAMP][VALUE]=%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_YEAR]%-%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MONTH]%-%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_DAY]% %VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_HOUR]%:%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_MINUTE]%:%VARIABLE[TIMESTAMP][DATE_TIME_CURRENT_SECOND]%
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция конвертации в нижний регистр:
:LOWERCASE
	SET VARIABLE[LOWERCASE][TEMP]=%~1
	FOR %%A IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO SET VARIABLE[LOWERCASE][TEMP]=!VARIABLE[LOWERCASE][TEMP]:%%~A!
	SET VARIABLE[LOWERCASE][VALUE]=%VARIABLE[LOWERCASE][TEMP]%
	SET VARIABLE[LOWERCASE][TEMP]=
GOTO END
REM ===========================================================================
REM ===========================================================================
REM Функция ведения LOG-файла и вывода текущей информации в консоль:
:LOG
REM Получили параметр (текст, который нужно записать в файл и вывести в консоль):
	SET VARIABLE[LOG][TEXT]=%~1
REM Запрещены знаки "!", а так же исправляем некоторые символы для совместимости:
	SET VARIABLE[LOG][TEXT]=%VARIABLE[LOG][TEXT]:""="%
	SET VARIABLE[LOG][TEXT]=%VARIABLE[LOG][TEXT]:'"="%
	SET VARIABLE[LOG][TEXT]=%VARIABLE[LOG][TEXT]:(=^^(%
	SET VARIABLE[LOG][TEXT]=%VARIABLE[LOG][TEXT]:)=^^)%
REM Задаем флаг о нахождении LOG-файла (пока не найден; нужен для того чтобы переданные текстовые данные не конфликтовали с вложенными IF'ами):
	SET VARIABLE[LOG][FLAG]=FALSE
REM Если текста нет, выходим:
	IF "%VARIABLE[LOG][TEXT]%" EQU "" GOTO END
REM Получаем текущее время:
	CALL :TIMESTAMP
REM Если в конфигурации задано ведение LOG файла:
	IF /I "%SETTINGS[DEFAULT][LOG_ENABLE]%" EQU "TRUE" (
REM Проверяем, существует ли путь к LOG-файлу:
		IF "%SETTINGS[PROGRAM][LOG][FILEPATH]%" NEQ "" (
REM Проверяем, существует имя LOG-файла:
			IF "%SETTINGS[PROGRAM][LOG][FILENAME]%" NEQ "" (
REM Если лог-файл найден...
				IF EXIST "%SETTINGS[PROGRAM][LOG][FILEPATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%" (
REM Если получили команду на очистку лог-файла:
					IF /I "%VARIABLE[LOG][TEXT]%" EQU "CLEAR" (
						TYPE>"%SETTINGS[PROGRAM][LOG][FILEPATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"2>NUL
						GOTO END
					)
				) ELSE (
REM Проверяем, если файла по указанному пути не существует, пытаемся его создать:
					TYPE>"%SETTINGS[PROGRAM][LOG][FILEPATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"2>NUL
				)
REM Если файл существует, меняем значение флага о нахождении LOG-файла (найден):
				IF EXIST "%SETTINGS[PROGRAM][LOG][FILEPATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%" (
					SET VARIABLE[LOG][FLAG]=TRUE
				)
			) ELSE (
				ECHO "%VARIABLE[TIMESTAMP][VALUE]%	[CONFIG][ERROR]	Filename for ""%SETTINGS[PROGRAM][LOG][FILENAME]%"" is empty."
			)
		) ELSE (
			ECHO "%VARIABLE[TIMESTAMP][VALUE]%	[CONFIG][ERROR]	Path for ""%SETTINGS[PROGRAM][LOG][FILEPATH]%"" is empty."
		)
	) ELSE (
		IF /I "%VARIABLE[LOG][TEXT]%" EQU "CLEAR" GOTO END
	)
REM Выводим информацию в консоль:
	ECHO %VARIABLE[TIMESTAMP][VALUE]%	%VARIABLE[LOG][TEXT]%
REM Если флаг говорит о том что файл не найден, выходим:
	IF /I "%VARIABLE[LOG][FLAG]%" NEQ "TRUE" (
		SET VARIABLE[TIMESTAMP][VALUE]=
		SET VARIABLE[LOG][FLAG]=
		GOTO END
	)
REM Если продолжаем, значит файл был найден и мы можем записать в него полученную информацию:
	ECHO %VARIABLE[TIMESTAMP][VALUE]%	%VARIABLE[LOG][TEXT]%>>"%SETTINGS[PROGRAM][LOG][FILEPATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"
	SET VARIABLE[TIMESTAMP][VALUE]=
	SET VARIABLE[LOG][FLAG]=
GOTO END
REM ===========================================================================
REM ===========================================================================
:END
GOTO :EOF
