@ECHO OFF
REM RUN EXAMPLES:
REM	xmrig-proxy.cmd
REM	xmrig-proxy.cmd --action=<start/restart/stop> --proxy=<proxy_name> --coin=<coin_name> --elevate=<true/false>
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
TITLE XMRig Proxy

REM Задаем путь, имя файла и расширение для файла конфигурации:
SET VARIABLE[CONFIG][PATH]=%~dp0
SET VARIABLE[CONFIG][FILENAME]=%~n0
SET VARIABLE[CONFIG][EXTENSION]=cfg
REM Получаем параметры коммандной строки:
SET VARIABLE[INPUT][COMMAND_PARAMETERS]=%*

REM ===========================================================================
REM ===========================================================================
REM Очищаем лог-файл, если задан и уже существует:
IF EXIST "%VARIABLE[CONFIG][PATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%" (
REM Загружаем данные конфигурации:
	FOR /F "usebackq" %%A IN ("%VARIABLE[CONFIG][PATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%") DO (
		SET VARIABLE[CONFIG][TEMP]=%%A
REM Если строка в файле конфигурации не пустая...
		IF "!VARIABLE[CONFIG][TEMP]!" NEQ "" (
REM Проверяем начало строки, - если она начинается с "#", то не загружаем строку как параметр конфигурации (считаем за комментарий):
			IF "!VARIABLE[CONFIG][TEMP]:~0,1!" NEQ "#" (
REM Все остальное задаем как параметры:
				CALL SET %%A
			)
		)
		SET VARIABLE[CONFIG][TEMP]=
	)
REM Проверка на необходимость очистки лог-файла при старте:
	IF /I "!SETTINGS[DEFAULT][LOG_CLEAR_ON_START]!" EQU "TRUE" CALL :LOG "CLEAR"
	CALL :LOG "[STATUS][INFO]	Starting..."
	IF "%VARIABLE[INPUT][COMMAND_PARAMETERS]%" NEQ "" CALL :LOG "[STATUS][INFO]	Input command parameters: '%VARIABLE[INPUT][COMMAND_PARAMETERS]%'."
REM Проверки на существование файлов по указанному пути в конфигурации:
	CALL :CONFIG_CHECK CSCRIPT
	CALL :CONFIG_CHECK NETSTAT
	CALL :CONFIG_CHECK TASKLIST
	CALL :CONFIG_CHECK TASKKILL
	CALL :CONFIG_CHECK TIMEOUT
	IF EXIST "!SETTINGS[PROGRAM][XMRIG][PATH]!\!SETTINGS[PROGRAM][XMRIG][FILENAME]!" (
		CALL :INIT
REM Задаем возможные значения для дейтсвия:
		SET SETTINGS[ACTION][1][NAME]=START
		SET SETTINGS[ACTION][2][NAME]=RESTART
		SET SETTINGS[ACTION][3][NAME]=STOP
REM Создаем список полученных данных по прокси:
		SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]=1
		SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]=0
		SET VARIABLE[CONFIG][ARRAY_LIST][TYPE]=PROXY
		CALL :CONFIG_ARRAY_LIST
REM Создаем список полученных данных по пулам:
		SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]=1
		SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]=0
		SET VARIABLE[CONFIG][ARRAY_LIST][TYPE]=POOL
		SET VARIABLE[CONFIG][COIN_LIST]=
		CALL :CONFIG_ARRAY_LIST
REM Работа с запросом повышения прав до уровня Администратора:
		IF EXIST "%SETTINGS[PROGRAM][CSCRIPT]%" (
			IF /I "%VARIABLE[INPUT][ELEVATE]%" EQU "TRUE" (
				NET SESSION >NUL 2>&1
				IF "%ERRORLEVEL%" EQU "0" CALL :START "ELEVATE"
			) ELSE (
				CALL :START
			)
		) ELSE (
			IF /I "%VARIABLE[INPUT][ELEVATE]%" EQU "TRUE" (
				NET SESSION >NUL 2>&1
				IF "%ERRORLEVEL%" EQU "0" (
					CALL :START "ELEVATE"
				) ELSE (
					CALL :LOG "[CONFIG][ERROR]	CSCRIPT file ^(""!SETTINGS[PROGRAM][CSCRIPT]!""^) not found."
				)
			) ELSE (
				CALL :START
			)
		)
	) ELSE (
		CALL :LOG "[CONFIG][ERROR][CRITICAL]	Program file ^(""!SETTINGS[PROGRAM][XMRIG][PATH]!\!SETTINGS[PROGRAM][XMRIG][FILENAME]!""^) not found. Exiting."
	)
) ELSE (
	CALL :LOG "[CONFIG][ERROR][CRITICAL]	Configuration file ^(""%VARIABLE[CONFIG][PATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]%""^) not found. Exiting."
)
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция получения параметров коммандной строки:
:INIT
REM Перебираем в цикле все значения через пробел:
	FOR /F "tokens=1*" %%A IN ("%VARIABLE[INPUT][COMMAND_PARAMETERS]%") DO (
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
			SET VARIABLE[INPUT][COMMAND_PARAMETERS]=%%B
			CALL :INIT
		)
	)
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция проверки нахождения путей и имен файлов в конфигурации:
:CONFIG_CHECK
	SET SETTINGS[PROGRAM][TEMP]=%~1
	CALL SET SETTINGS[PROGRAM][TEMP][PATH]=%%SETTINGS[PROGRAM][%SETTINGS[PROGRAM][TEMP]%][PATH]%%
	CALL SET SETTINGS[PROGRAM][TEMP][FILENAME]=%%SETTINGS[PROGRAM][%SETTINGS[PROGRAM][TEMP]%][FILENAME]%%
	IF "%SETTINGS[PROGRAM][TEMP][PATH]%" NEQ "" (
		IF "%SETTINGS[PROGRAM][TEMP][FILENAME]%" NEQ "" (
			IF EXIST "%SETTINGS[PROGRAM][TEMP][PATH]%\%SETTINGS[PROGRAM][TEMP][FILENAME]%" (
				CALL :LOG "[CONFIG][INFO]	Path and filename for ""%SETTINGS[PROGRAM][TEMP]%"" successfully tested."
				CALL SET SETTINGS[PROGRAM][%SETTINGS[PROGRAM][TEMP]%]=%SETTINGS[PROGRAM][TEMP][PATH]%\%SETTINGS[PROGRAM][TEMP][FILENAME]%
			) ELSE (
				CALL :LOG "[CONFIG][ERROR]	Path and filename for ""%SETTINGS[PROGRAM][TEMP]%"" not found at ""%SETTINGS[PROGRAM][TEMP]%""."
			)
		) ELSE (
			CALL :LOG "[CONFIG][ERROR]	Filename for ""%SETTINGS[PROGRAM][TEMP]%"" is empty."
		)
	) ELSE (
		CALL :LOG "[CONFIG][ERROR]	Path for ""%SETTINGS[PROGRAM][TEMP]%"" is empty."
	)
	SET SETTINGS[PROGRAM][TEMP][PATH]=
	SET SETTINGS[PROGRAM][TEMP][FILENAME]=
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция создания массива (списка) имен из всех указанных в конфигурации значений:
:CONFIG_ARRAY_LIST
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT] SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]%
REM Разбор значений в случае если запрос относился к прокси:
	IF "%VARIABLE[CONFIG][ARRAY_LIST][TYPE]%" EQU "PROXY" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME] (
			IF %VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% EQU 1 (
				CALL :LOG "[CONFIG][INFO]	Loading %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% data..."
			)
REM Если значение есть, выводим информацию и присваиваем его переменной:
			CALL :LOG "[CONFIG][INFO]		Found proxy: ""%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME]%%"" ^(""%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][ADDRESS]%%:%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][PORT]%%""^)"
REM Увеличиваем значение счетчика и переходим в начало цикла:
			SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% + 1
			GOTO :CONFIG_ARRAY_LIST
		) ELSE (
			SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% - 1
		)
	)
REM Разбор значений в случае если запрос относился к монете:
	IF "%VARIABLE[CONFIG][ARRAY_LIST][TYPE]%" EQU "POOL" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME] (
			IF %VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% EQU 1 (
				CALL :LOG "[CONFIG][INFO]	Loading %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% data..."
			)
REM Если значение есть, выводим информацию и присваиваем его переменной:
			CALL :LOG "[CONFIG][INFO]		Found pool for coin: ""%%SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][COIN]%%"" ^(NAME: ""%%SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME]%%""^)"
			CALL SET VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]=%%SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][COIN]%%
REM Дополнительно создаем спиок монет:
			CALL :CONFIG_COIN_LIST
REM Увеличиваем значение счетчика и переходим в начало цикла:
			SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% + 1
			GOTO :CONFIG_ARRAY_LIST
		) ELSE (
			SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% - 1
		)
	)
	IF %VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]% EQU 0 (
		CALL :LOG "[CONFIG][ERROR]	No one %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% found in configuration."
	) ELSE (
		CALL :LOG "[CONFIG][INFO]	Total %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% found in configuration: %VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]%"
	)
	SET VARIABLE[CONFIG][ARRAY_LIST][TYPE]=
	SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция поиска по массиву с добавлением в список тестового значения (если его там нет):
:CONFIG_COIN_LIST
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[CONFIG][COIN_LIST][COUNT] SET /A VARIABLE[CONFIG][COIN_LIST][COUNT]=1
REM Если массив еще не закончился (текущее порядковое значение имени читается):
	IF DEFINED VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CONFIG][COIN_LIST][COUNT]%][NAME] (
REM Задаем переменную с текущим значением имени из массива (по которому идем по списку от стартового значения до тех пор пока есть значения в массиве):
		CALL SET VARIABLE[CONFIG][COIN_LIST][VALUE_CURRENT]=%%VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CONFIG][COIN_LIST][COUNT]%][NAME]%%
REM Если заданная переменная имени текущего значения массива не совпадает с тестовым значением, то повторяем цикл, увеличивая счетчик и удаляя текущее значение (нам нужно пройти весь цикл и либо найти совпадение, тогда выход, так как добавлять уже нечего, либо в самом конце, если не находим, добавляем тестовое значение):
		IF "!VARIABLE[CONFIG][COIN_LIST][VALUE_CURRENT]!" NEQ "!VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]!" (
			SET /A VARIABLE[CONFIG][COIN_LIST][COUNT]=%VARIABLE[CONFIG][COIN_LIST][COUNT]% + 1
			SET VARIABLE[CONFIG][COIN_LIST][VALUE_CURRENT]=
			GOTO :CONFIG_COIN_LIST
REM Если заданная переменная текущего значения массива совпадает с тестовым значением, то выходим из функции, ничего не делая (тестовое значение уже есть в массиве):
		) ELSE (
			SET VARIABLE[CONFIG][COIN_LIST][VALUE_CURRENT]=
			SET VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]=
			GOTO :END
		)
REM Если значение имени в массиве с текущим счетчиком не удалось прочитать, значит массив закончился, а искомого тестового значения мы так и не нашли:
	) ELSE (
REM Добавляем тестовое значение в массив:
		SET VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CONFIG][COIN_LIST][COUNT]%][NAME]=!VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]!
		SET VARIABLE[CONFIG][COIN_LIST][VALUE_TEST]=
		SET VARIABLE[CONFIG][COIN_LIST][COUNT]=
		GOTO :END
	)
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция проверки выбора ввода:
:CHECK
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
		GOTO :CHECK_INPUT_SET_TRUE
REM Если значение не задано:
	) ELSE (
		GOTO :CHECK_INPUT_SET_FALSE
	)
REM Очищаем значения:
	SET VARIABLE[CHECK][VALUE_TEST]=
	SET VARIABLE[CHECK][TYPE]=
	SET VARIABLE[CHECK][RETRY]=
GOTO END
:CHECK_INPUT_SET_TRUE
	IF "%VARIABLE[CHECK][TYPE]%" EQU "ACTION" (
		CALL :CHECK_INPUT_SET_TRUE_IF_DEFINED %%SETTINGS[%VARIABLE[CHECK][TYPE]%][%VARIABLE[CHECK][COUNT]%][NAME]%%
	)
	IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
		CALL :CHECK_INPUT_SET_TRUE_IF_DEFINED %%SETTINGS[%VARIABLE[CHECK][TYPE]%][%VARIABLE[CHECK][COUNT]%][NAME]%%
	)
	IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
		CALL :CHECK_INPUT_SET_TRUE_IF_DEFINED_COIN
	)
GOTO END
:CHECK_INPUT_SET_TRUE_IF_DEFINED
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[%VARIABLE[CHECK][TYPE]%][%VARIABLE[CHECK][COUNT]%][NAME] (
REM Если значение есть, задаем его в переменной и проверяем дальше:
		CALL SET VARIABLE[CHECK][VALUE_CURRENT]=%~1
		GOTO :CHECK_INPUT_SET_TRUE_DEFINED_TRUE
REM Если прошли весь массив значений монет, а выбранной записи так и не обнаружено:
	) ELSE (
REM Повторно пробуем задать значение или берем его из параметра по умолчанию:
		GOTO :CHECK_INPUT_SET_TRUE_DEFINED_FALSE
	)
GOTO END
:CHECK_INPUT_SET_TRUE_IF_DEFINED_COIN
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CHECK][COUNT]%][NAME] (
REM Если значение есть, задаем его в переменной и проверяем дальше:
		CALL SET VARIABLE[CHECK][VALUE_CURRENT]=%%VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CHECK][COUNT]%][NAME]%%
		GOTO :CHECK_INPUT_SET_TRUE_DEFINED_TRUE
REM Если прошли весь массив значений монет, а выбранной записи так и не обнаружено:
	) ELSE (
REM Повторно пробуем задать значение или берем его из параметра по умолчанию:
		GOTO :CHECK_INPUT_SET_TRUE_DEFINED_FALSE
	)
GOTO END
:CHECK_INPUT_SET_TRUE_DEFINED_TRUE
REM Проверяем на свопадение текущего значения из массива и ранее заданного искомого:
	IF /I "%VARIABLE[CHECK][VALUE_CURRENT]%" EQU "%VARIABLE[CHECK][VALUE_TEST]%" (
REM Извещаем об успешном нахождении:
		CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
		CALL :LOG "[STATUS][INFO]	Selected ""!VARIABLE[CHECK][VALUE_CURRENT]!"" !VARIABLE[LOWERCASE][VALUE]!."
		SET VARIABLE[LOWERCASE][VALUE]=
REM Задаем искомое значение:
		SET VARIABLE[CHECK][VALUE]=%VARIABLE[CHECK][VALUE_CURRENT]%
REM Выходим:
		SET VARIABLE[CHECK][VALUE_CURRENT]=
		SET VARIABLE[CHECK][VALUE_TEST]=
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		SET VARIABLE[CHECK][RETRY]=
		GOTO :END
	) ELSE (
REM Увеличиваем значение счетчика положения в массиве и переходим в начало цикла:
		SET /A VARIABLE[CHECK][COUNT]=%VARIABLE[CHECK][COUNT]% + 1
		SET VARIABLE[CHECK][VALUE_CURRENT]=
		GOTO :CHECK
	)
GOTO END
:CHECK_INPUT_SET_TRUE_DEFINED_FALSE
REM Если задана возможность ручного ввода данных:
	IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%" EQU "TRUE" (
		CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
		CALL :LOG "[INPUT][ERROR]	Selected ""%VARIABLE[CHECK][VALUE_TEST]%"" is not correct !VARIABLE[LOWERCASE][VALUE]!. Please, try again..."
REM Сбрасываем неправильное значение:
		SET VARIABLE[CHECK][VALUE_TEST]=
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
		CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
		CALL :TIMESTAMP
REM Получаем значение из консоли:
		SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a !VARIABLE[LOWERCASE][VALUE]! (<ENTER> for default value) !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		SET VARIABLE[LOWERCASE][VALUE]=
REM Увеличиваем счетчик проходов:
		SET /A VARIABLE[CHECK][RETRY]=%VARIABLE[CHECK][RETRY]% + 1
REM Сбрасываем счетчик положения в массиве в начальное положение:
		SET /A VARIABLE[CHECK][COUNT]=1
REM Снова проходим тестирование на совпадение:
		GOTO :CHECK
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию:
	) ELSE (
		CALL :CHECK_INPUT_AUTOMATIC_TEST %VARIABLE[CHECK][TYPE]% %%SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]%%
REM Сбрасываем счетчики и выходим:
		SET VARIABLE[CHECK][VALUE_TEST]=
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		SET VARIABLE[CHECK][RETRY]=
		GOTO :END
	)
GOTO END
:CHECK_INPUT_SET_FALSE
REM Если задана возможность ручного ввода данных:
	IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%" EQU "TRUE" (
		CALL :LOWERCASE %VARIABLE[CHECK][TYPE]%
REM Если это не первый проход цикла и ввод пустой, предлагаем ввести значение по умолчанию:
		IF %VARIABLE[CHECK][RETRY]% GEQ 2 (
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
				GOTO :CHECK
			) ELSE (
				IF /I "!VARIABLE[CHECK][DEFAULT]!" EQU "N" (
					SET VARIABLE[CHECK][DEFAULT]=
				) ELSE (
					GOTO :CHECK_INPUT_SET_FALSE
				)
			)
		)
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
		CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
		CALL :TIMESTAMP
REM Получаем значение из консоли:
		SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a !VARIABLE[LOWERCASE][VALUE]! (<ENTER> for default value) !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		SET VARIABLE[LOWERCASE][VALUE]=
REM Увеличиваем счетчик проходов:
		SET /A VARIABLE[CHECK][RETRY]=%VARIABLE[CHECK][RETRY]% + 1
REM Сбрасываем счетчик положения в массиве в начальное положение:
		SET /A VARIABLE[CHECK][COUNT]=1
REM Снова проходим тестирование на совпадение:
		GOTO :CHECK
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию:
	) ELSE (

		CALL :CHECK_INPUT_AUTOMATIC_TEST %VARIABLE[CHECK][TYPE]% %%SETTINGS[DEFAULT][%VARIABLE[CHECK][TYPE]%]%%
REM Сбрасываем счетчики и выходим:
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		SET VARIABLE[CHECK][RETRY]=
		GOTO :END
	)
GOTO END
:CHECK_INPUT_AUTOMATIC_TEST
	IF "%VARIABLE[CHECK][TYPE]%" EQU "%~1" (
		CALL :LOWERCASE %~1
		IF "%VARIABLE[CHECK][RETRY]%" EQU "1" (
			CALL :LOG "[STATUS][ERROR]	Input value not found. Default value ^(""--!VARIABLE[LOWERCASE][VALUE]!=%~2""^) was set."
			SET VARIABLE[LOWERCASE][VALUE]=
			SET VARIABLE[CHECK][VALUE_TEST]=%~2
REM Увеличиваем счетчик проходов:
			SET /A VARIABLE[CHECK][RETRY]=%VARIABLE[CHECK][RETRY]% + 1
			GOTO :CHECK
		) ELSE (
			CALL :LOG "[CONFIG][ERROR][CRITICAL] Default value ^(""--!VARIABLE[LOWERCASE][VALUE]!=%~2""^) does not match with configuration set. Exiting."
			EXIT
		)
	)
GOTO END
REM Функция формирования текста для подсказки выбора:
:CHECK_INPUT_TEXT_FORMAT
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано), обнуляем на всякий случай значение результата и задаем тип поиска:
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT] (
		SET /A VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=1
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=%~1
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=
	)
REM Задаем начальное значение текста:
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE] SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=[
	IF "%VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]%" EQU "ACTION" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[ACTION][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME] (
REM Если значение есть, присваиваем его временной переменной:
			CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE_CURRENT]=%%SETTINGS[ACTION][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME]%%
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_TRUE
		) ELSE (
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_FALSE
		)
	)
	IF "%VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]%" EQU "PROXY" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[PROXY][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME] (
REM Если значение есть, присваиваем его временной переменной:
			CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE_CURRENT]=%%SETTINGS[PROXY][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME]%%
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_TRUE
		) ELSE (
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_FALSE
		)
	)
	IF "%VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]%" EQU "COIN" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME] (
REM Если значение есть, присваиваем его временной переменной:
			CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE_CURRENT]=%%VARIABLE[CONFIG][COIN_LIST][ARRAY][%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]%][NAME]%%
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_TRUE
		) ELSE (
			GOTO :CHECK_INPUT_TEXT_FORMAT_DEFINED_FALSE
		)
	)
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=
GOTO END
:CHECK_INPUT_TEXT_FORMAT_DEFINED_TRUE
REM Если это первый проход цикла, то ставим разделитель "/":
	IF %VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]% GTR 1 CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=%VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]% /
REM Добавляем к концу строки переменной найденное значение:
	CALL SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=%VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]% %VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE_CURRENT]%
REM Обнуляем временную переменную, увеличиваем значение счетчика и переходим в начало цикла:
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE_CURRENT]=
	SET /A VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=%VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]% + 1
	GOTO :CHECK_INPUT_TEXT_FORMAT
GOTO END
:CHECK_INPUT_TEXT_FORMAT_DEFINED_FALSE
REM Задаем окончательное значение текста:
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=%VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]% ]
REM Сбрасываем счетчик и выходим:
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=
	SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция повышения прав через внутренний запуск VBS-скрипта:
:ELEVATE
REM Создаем скрипт-файл VBS со строкой запуска:
	ECHO CreateObject^("Shell.Application"^).ShellExecute "%~snx0","ELEVATE %~1","%~sdp0","runas","%PROGRAM_TITLE%">"%TEMP%\%PROGRAM_FILENAME%.vbs"
REM Запускаем созданный скрипт-файл:
	%CSCRIPT% //nologo "%TEMP%\%PROGRAM_FILENAME%.vbs"
REM Удаляем созданный скрипт-файл:
	IF EXIST "%TEMP%\%PROGRAM_FILENAME%.vbs" DEL "%TEMP%\%PROGRAM_FILENAME%.vbs"
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция создания параметров коммандной строки для запуска программы:
:PARAMETERS
	CALL :PARAMETERS_PROXY_GET
	CALL :PARAMETERS_PROXY_TO_STRING
REM Добавляем в строку параметров для программы полученные данные по прокси:
	IF "%VARIABLE[PROGRAM][PARAMETERS][PROXY]%" NEQ "" (
		CALL :PARAMETERS_POOL_GET
		CALL :PARAMETERS_POOL_TO_STRING
		IF "!VARIABLE[PROGRAM][PARAMETERS][POOLS]!" NEQ "" (
REM Добавляем в строку параметров для программы полученные данные по прокси и пулам:
			SET VARIABLE[PROGRAM][XMRIG][PARAMETERS]=%VARIABLE[PROGRAM][PARAMETERS][PROXY]% !VARIABLE[PROGRAM][PARAMETERS][POOLS]!
REM Добавляем в строку параметров для программы данные по умолчанию, указанные в конфигурации (если там что-то есть):
			IF "%SETTINGS[PROGRAM][XMRIG][PARAMETERS]%" NEQ "" SET VARIABLE[PROGRAM][XMRIG][PARAMETERS]=!VARIABLE[PROGRAM][XMRIG][PARAMETERS]! %SETTINGS[PROGRAM][XMRIG][PARAMETERS]%
		)
	)
GOTO END
:PARAMETERS_PROXY_GET
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]%
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		CALL SET VARIABLE[PARAMETERS][PROXY][CURRENT]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NAME]%%
		IF "!VARIABLE[PARAMETERS][PROXY][CURRENT]!" EQU "%VARIABLE[CHECK][VALUE][PROXY]%" (
			CALL SET VARIABLE[PARAMETERS][PROXY][NAME]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NAME]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][ALGORYTM]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][ALGORYTM]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][ADDRESS]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][ADDRESS]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][PORT]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][PORT]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][API]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][API]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][TOKEN]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][TOKEN]%%
			CALL SET VARIABLE[PARAMETERS][PROXY][NO-RESTRICTED]=%%SETTINGS[PROXY][%VARIABLE[PARAMETERS][COUNT]%][NO-RESTRICTED]%%
			SET VARIABLE[PARAMETERS][PROXY][CURRENT]=
			SET VARIABLE[PARAMETERS][COUNT]=
			GOTO :END
		) ELSE (
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][PROXY][CURRENT]=
			GOTO :PARAMETERS_PROXY_GET
		)
	) ELSE (
		SET VARIABLE[PARAMETERS][COUNT]=
		GOTO :END
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
	CALL :LOG "[STATUS][ERROR][CRITICAL]	Parameter ""%~1"" in configuration was not set for proxy: ""%VARIABLE[PARAMETERS][PROXY][NAME]%"". Proxy will not be used. Exiting."
GOTO END
:PARAMETERS_POOL_GET
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]%
	IF NOT DEFINED VARIABLE[PARAMETERS][POOL][COUNT] SET /A VARIABLE[PARAMETERS][POOL][COUNT]=1
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		CALL SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][COIN]%%
REM Если заданная монета пула совпадает с тем что мы перебираем из конфигурации...
		IF "!VARIABLE[PARAMETERS][POOL][CURRENT][COIN]!" EQU "%VARIABLE[CHECK][VALUE][COIN]%" (
REM Получем значение алгоритма для текущего пула:
			CALL SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][ALGORYTM]%%
REM Проверяем, совпадают-ли алгоритмы с тем, который задан в прокси:
			IF /I "!VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]!" EQU "%VARIABLE[PARAMETERS][PROXY][ALGORYTM]%" (
REM Формируем новый список (массив) пулов, которые нам подходят для использования
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][NAME]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][ALGORYTM]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][ALGORYTM]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][ADDRESS]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][ADDRESS]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][PORT]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][PORT]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][DIFF]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][DIFF]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][ID]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][ID]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][EMAIL]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][EMAIL]%%
				CALL SET VARIABLE[PARAMETERS][POOL][%%VARIABLE[PARAMETERS][POOL][COUNT]%%][WALLET]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][WALLET]%%
REM Увеличиваем значения счетчиков (основного, по циклу, и второго - счетчик элементов в новом массиве) и переходим в начало цикла:
				SET /A VARIABLE[PARAMETERS][POOL][COUNT]=%VARIABLE[PARAMETERS][POOL][COUNT]% + 1
				SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=
			) ELSE (
				CALL SET VARIABLE[PARAMETERS][POOL][CURRENT][NAME]=%%SETTINGS[POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME]%%
				CALL :LOG "[STATUS][ERROR]	Found correct pool ^(""!VARIABLE[PARAMETERS][POOL][CURRENT][NAME]!""^) for ""%VARIABLE[CHECK][VALUE][COIN]%"" coin, but algorytm with proxy ^(""%VARIABLE[PARAMETERS][PROXY][NAME]%""^) is different. Ignored."
				SET VARIABLE[PARAMETERS][POOL][CURRENT][NAME]=
				SET VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]=
			)
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=
			GOTO :PARAMETERS_POOL_GET
		) ELSE (
REM Если значения не совпадает, пропускаем данный пул, не добавляя его в новый массив, увеличиваем значение основного счетчика и переходим в начало цикла:
			SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
			SET VARIABLE[PARAMETERS][POOL][CURRENT][COIN]=
			GOTO :PARAMETERS_POOL_GET
		)
	) ELSE (
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[PARAMETERS][COUNT]=
		GOTO :END
	)
GOTO END
:PARAMETERS_POOL_TO_STRING
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[PARAMETERS][COUNT] SET /A VARIABLE[PARAMETERS][COUNT]=1
REM Перебираем весь массив и проверяем, задано ли значение NAME:
	IF DEFINED VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][NAME] (
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][ADDRESS]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][ADDRESS]%%
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][PORT]%%
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][WALLET]%%
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][DIFF]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][DIFF]%%
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][ID]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][ID]%%
		CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][EMAIL]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][EMAIL]%%
		IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][ADDRESS]!" NEQ "" (
			IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]!" NEQ "" (
				IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]!" NEQ "" (
					IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][ID]!" NEQ "" (
						CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]=--url=!VARIABLE[PROGRAM][PARAMETERS][POOL][ADDRESS]!:!VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]! --user=!VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]!+!VARIABLE[PROGRAM][PARAMETERS][POOL][DIFF]! --pass=!VARIABLE[PROGRAM][PARAMETERS][POOL][ID]!:!VARIABLE[PROGRAM][PARAMETERS][POOL][EMAIL]!
					) ELSE (
						CALL :LOG "[STATUS][ERROR]	Parameter ""ID"" in configuration was not set for pool: ""%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"". Pool will not be added to list."
					)
				) ELSE (
					CALL :LOG "[STATUS][ERROR]	Parameter ""WALLET"" in configuration was not set for pool: ""%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"". Pool will not be added to list."
				)
			) ELSE (
				CALL :LOG "[STATUS][ERROR]	Parameter ""PORT"" in configuration was not set for pool: ""%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"". Pool will not be added to list."
			)
		) ELSE (
			CALL :LOG "[STATUS][ERROR]	Parameter ""ADDRESS"" in configuration was not set for pool: ""%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"". Pool will not be added to list."
		)
		IF "!VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!" NEQ "" (
			IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOLS] (
				CALL SET VARIABLE[PROGRAM][PARAMETERS][POOLS]=!VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!
			) ELSE (
				CALL SET VARIABLE[PROGRAM][PARAMETERS][POOLS]=%VARIABLE[PROGRAM][PARAMETERS][POOLS]% !VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]!
			)
			SET VARIABLE[PROGRAM][PARAMETERS][POOL][STRING]=
		)
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][EMAIL]=
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][ID]=
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][DIFF]=
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][WALLET]=
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][PORT]=
		SET VARIABLE[PROGRAM][PARAMETERS][POOL][URL]=
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
		GOTO :PARAMETERS_POOL_TO_STRING
	) ELSE (
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[PARAMETERS][COUNT]=
		GOTO :END
	)
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция запуска программы с параметрами:
:START
REM Получаем проверенные значения выбора:
	CALL :CHECK "ACTION"
	SET VARIABLE[CHECK][VALUE][ACTION]=%VARIABLE[CHECK][VALUE]%
	CALL :CHECK "PROXY"
	SET VARIABLE[CHECK][VALUE][PROXY]=%VARIABLE[CHECK][VALUE]%
	CALL :CHECK "COIN"
	SET VARIABLE[CHECK][VALUE][COIN]=%VARIABLE[CHECK][VALUE]%
REM Формируем строку параметров для запуска программы:
	CALL :PARAMETERS
REM Если параметры для запуска получены, переходим к процессу действия:
	IF "%VARIABLE[PROGRAM][XMRIG][PARAMETERS]%" NEQ "" (
		IF "%VARIABLE[CHECK][VALUE][ACTION]%" NEQ "" (
			CALL :ACTION %~1
		) ELSE (
			CALL :LOG "[STATUS][INFO]	Action is not set. Nothing to do. Exiting."
		)
	)
GOTO END

REM ===========================================================================
REM ===========================================================================

REM Функция проверки требуемого действия:
:ACTION
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
					IF /I "%VARIABLE[CHECK][VALUE][ACTION]%" EQU "START" (
						CALL :LOG "[STATUS][INFO]	Proxy already started ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Nothing to do. Exiting."
					) ELSE (
REM Проверяем, доступен ли заданный в конфигурации файл "TASKKILL":
						IF EXIST "%SETTINGS[PROGRAM][TASKKILL]%" (
							IF VARIABLE[ACTION][COUNT] GEQ %SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]% (
								CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not stop already started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Maximum attempts ^(%SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]%^) reached while trying to stop a running process. Exiting."
								SET VARIABLE[ACTION][COUNT]=
								GOTO END
							) ELSE (
								IF VARIABLE[ACTION][COUNT] EQU 1 (
									CALL :LOG "[STATUS][INFO]	Found started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^). Trying to stop it..."
								) ELSE (
									CALL :LOG "[STATUS][ERROR]	Can not stop already started process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^) for this instance. Retry attempt %VARIABLE[ACTION][COUNT]% of %SETTINGS[DEFAULT][RETRY_MAXIMUM_ATTEMPTS]%..."
								)
								CALL :ACTION_STOP
								SET /A VARIABLE[ACTION][COUNT]=%VARIABLE[ACTION][COUNT]% + 1
								CALL :TIMEWAIT 1
								GOTO :ACTION
							)
						) ELSE (
							CALL :LOG "[STATUS][ERROR][CRITICAL]	Can not stop process ^(PID: ""!VARIABLE[PROGRAM][PID][TASKLIST]!""; Name: ""%SETTINGS[PROGRAM][XMRIG][FILENAME]%"" ; Port: ""%VARIABLE[PARAMETERS][PROXY][PORT]%""^), because ""TASKKILL"" file not found at ""%SETTINGS[PROGRAM][TASKKILL][PATH]%\%SETTINGS[PROGRAM][TASKKILL][FILENAME]%"". Please close and stop process manually. Exiting."
						)
					)
				) ELSE (
					CALL :LOG "[STATUS][ERROR][CRITICAL]	Requested port ""!VARIABLE[PROGRAM][PID][NETSTAT]!"" is busy by another process. Please release port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" manually before start a program. Can not continue. Exiting."
				)
			) ELSE (
				CALL :LOG "[STATUS][ERROR][CRITICAL]	Requested port is busy by PID ""!VARIABLE[PROGRAM][PID][NETSTAT]!"", but can not check wich process is running on it, because ""TASKLIST"" file not found at ""%SETTINGS[PROGRAM][TASKLIST][PATH]%\%SETTINGS[PROGRAM][TASKLIST][FILENAME]%"". Please release port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" manually before start a program. Can not continue. Exiting."
			)
		) ELSE (
			IF /I "%VARIABLE[CHECK][VALUE][ACTION]%" EQU "START" (
				CALL :ACTION_START %~1
			) ELSE (
				IF /I "%VARIABLE[CHECK][VALUE][ACTION]%" EQU "RESTART" (
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
						CALL :LOG "[STATUS][INFO]	Changing action to ""START""..."
						SET VARIABLE[CHECK][VALUE][ACTION]=START
						SET VARIABLE[INPUT][TEMP]=
						GOTO :ACTION
					) ELSE (
						IF /I "!VARIABLE[INPUT][TEMP]!" EQU "N" (
							CALL :LOG "[STATUS][INFO]	Exiting."
							SET VARIABLE[INPUT][TEMP]=
						) ELSE (
							GOTO :ACTION
						)
					)
				) ELSE (
					CALL :LOG "[STATUS][ERROR][CRITICAL]	Requested proxy ""%VARIABLE[PARAMETERS][PROXY][NAME]%"" is not running (port ""%VARIABLE[PARAMETERS][PROXY][PORT]%"" not found in a process list), can not stop it. Exiting."
				)
			)
		)
	) ELSE (
		IF /I "%VARIABLE[CHECK][VALUE][ACTION]%" EQU "START" (
			CALL :LOG "[STATUS][ERROR]	Can not check requested port (is it busy or not) before start a program, because ""NETSTAT"" file not found at ""%SETTINGS[PROGRAM][NETSTAT][PATH]%\%SETTINGS[PROGRAM][NETSTAT][FILENAME]%""."
			IF /I "%SETTINGS[DEFAULT][ALLOW_START_WITHOUT_PID_CHECK]%" EQU "TRUE" (
				CALL :LOG "[STATUS][INFO]	Found positive flag (""ALLOW_START_WITHOUT_PID_CHECK"" is set to ""TRUE"") in configuration to start a program."
				CALL :ACTION_START %~1
				SET VARIABLE[ACTION][COUNT]=
				GOTO END
			)
		)
		CALL :LOG "[STATUS][ERROR]	Can not check requested port (is it busy or not) before start a program, because ""NETSTAT"" file not found at ""%SETTINGS[PROGRAM][NETSTAT][PATH]%\%SETTINGS[PROGRAM][NETSTAT][FILENAME]%"". Can not continue. Exiting."
	)
	SET VARIABLE[ACTION][COUNT]=
GOTO END
:ACTION_START
	CD "%SETTINGS[PROGRAM][XMRIG][PATH]%"
REM В заивисимости от того задано ли повышение прав до уровня Администратора или нет, запускаем программу разными методами (в отлельном окне, или в том же самом):
	IF "%~1" EQU "ELEVATE" (
		CALL :LOG "[STATUS][INFO]	Starting: %SETTINGS[PROGRAM][XMRIG][PATH]%\%SETTINGS[PROGRAM][XMRIG][FILENAME]% %VARIABLE[PROGRAM][XMRIG][PARAMETERS]%"
		CALL "%SETTINGS[PROGRAM][XMRIG][PATH]%\%SETTINGS[PROGRAM][XMRIG][FILENAME]%" %VARIABLE[PROGRAM][XMRIG][PARAMETERS]%
	) ELSE (
		CALL :LOG "[STATUS][INFO]	Starting: START %SETTINGS[PROGRAM][TITLE]% /D %SETTINGS[PROGRAM][XMRIG][PATH]% %SETTINGS[PROGRAM][XMRIG][FILENAME]% %VARIABLE[PROGRAM][XMRIG][PARAMETERS]%"
		START "%SETTINGS[PROGRAM][TITLE]%" /D "%SETTINGS[PROGRAM][XMRIG][PATH]%" "%SETTINGS[PROGRAM][XMRIG][FILENAME]%" %VARIABLE[PROGRAM][XMRIG][PARAMETERS]%
	)
GOTO END
:ACTION_STOP
	%SETTINGS[PROGRAM][TASKKILL]% /F /PID %VARIABLE[PROGRAM][PID][TASKLIST]%>NUL
GOTO END

REM ===========================================================================
REM ===========================================================================

:LOWERCASE
	SET VARIABLE[LOWERCASE][TEMP]=%~1
	FOR %%A IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO SET VARIABLE[LOWERCASE][TEMP]=!VARIABLE[LOWERCASE][TEMP]:%%~A!
	SET VARIABLE[LOWERCASE][VALUE]=%VARIABLE[LOWERCASE][TEMP]%
	SET VARIABLE[LOWERCASE][TEMP]=
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
		%SETTINGS[PROGRAM][TIMEOUT]% %VARIABLE[TIMEWAIT][VALUE]%>NUL
REM Если файл не задан или не существует, то решаем задачу через встроенную возможность задать интервал в PING:
	) ELSE (
		PING 127.0.0.1 -n "%VARIABLE[TIMEWAIT][VALUE]%">NUL
	)
REM Сбрасываем текущее значение:
	SET VARIABLE[TIMEWAIT][VALUE]=
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
		IF "%SETTINGS[PROGRAM][LOG][PATH]%" NEQ "" (
REM Проверяем, существует имя LOG-файла:
			IF "%SETTINGS[PROGRAM][LOG][FILENAME]%" NEQ "" (
REM Если лог-файл найден...
				IF EXIST "%SETTINGS[PROGRAM][LOG][PATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%" (
REM Если получили команду на очистку лог-файла:
					IF /I "%VARIABLE[LOG][TEXT]%" EQU "CLEAR" (
						TYPE>"%SETTINGS[PROGRAM][LOG][PATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"2>NUL
						GOTO END
					)
				) ELSE (
REM Проверяем, если файла по указанному пути не существует, пытаемся его создать:
					TYPE>"%SETTINGS[PROGRAM][LOG][PATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"2>NUL
				)
REM Если файл существует, меняем значение флага о нахождении LOG-файла (найден):
				IF EXIST "%SETTINGS[PROGRAM][LOG][PATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%" (
					SET VARIABLE[LOG][FLAG]=TRUE
				)
			) ELSE (
				ECHO "%VARIABLE[TIMESTAMP][VALUE]%	[CONFIG][ERROR]	Filename for ""%SETTINGS[PROGRAM][LOG][FILENAME]%"" is empty."
			)
		) ELSE (
			ECHO "%VARIABLE[TIMESTAMP][VALUE]%	[CONFIG][ERROR]	Path for ""%SETTINGS[PROGRAM][LOG][PATH]%"" is empty."
		)
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
	ECHO %VARIABLE[TIMESTAMP][VALUE]%	%VARIABLE[LOG][TEXT]%>>"%SETTINGS[PROGRAM][LOG][PATH]%\%SETTINGS[PROGRAM][LOG][FILENAME]%"
	SET VARIABLE[TIMESTAMP][VALUE]=
	SET VARIABLE[LOG][FLAG]=
GOTO END

REM ===========================================================================
REM ===========================================================================

:END
GOTO :EOF
