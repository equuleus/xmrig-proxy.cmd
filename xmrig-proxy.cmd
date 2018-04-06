@ECHO OFF
REM RUN EXAMPLES:
REM	xmrig-proxy.cmd
REM	xmrig-proxy.cmd --proxy=<proxy_name> --coin=<coin_name> --elevate=<true/false>
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION
CLS
TITLE XMRig Proxy

REM Задаем путь, имя файла и расширение для файла конфигурации:
SET VARIABLE[CONFIG][PATH]=%~dp0
SET VARIABLE[CONFIG][FILENAME]=%~n0
SET VARIABLE[CONFIG][EXTENSION]=cfg.cmd
REM Получаем параметры коммандной строки:
SET VARIABLE[INPUT][COMMAND_PARAMETERS]=%*

IF EXIST "%CONFIG_PATH%\%CONFIG_FILENAME%.%CONFIG_EXTENSION%" (
	CALL :TIMESTAMP
	ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO]	Starting...
	ECHO.
REM Загружаем данные конфигурации:
	CALL %VARIABLE[CONFIG][PATH]%\%VARIABLE[CONFIG][FILENAME]%.%VARIABLE[CONFIG][EXTENSION]% > NUL
	IF EXIST "!SETTINGS[PROGRAM][PATH]!\!SETTINGS[PROGRAM][FILENAME]!" (
		CALL :INIT
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
		ECHO.
		IF EXIST "%SETTINGS[PROGRAM][CSCRIPT]%" (
			IF /I "%VARIABLE[INPUT][ELEVATE]%"=="TRUE" (
				NET SESSION >NUL 2>&1
				IF "%ERRORLEVEL%" EQU "0" CALL :START "ELEVATE"
			) ELSE (
				CALL :START
			)
		) ELSE (
			IF /I "%VARIABLE[INPUT][ELEVATE]%"=="TRUE" (
				NET SESSION >NUL 2>&1
				IF "%ERRORLEVEL%" EQU "0" (
					CALL :START "ELEVATE"
				) ELSE (
					CALL :TIMESTAMP
					ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][ERROR]	CSCRIPT FILE ^("!SETTINGS[PROGRAM][CSCRIPT]!"^) NOT FOUND^^!
					CALL :START
				)
			) ELSE (
				CALL :START
			)
		)
	) ELSE (
		CALL :TIMESTAMP
		ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][ERROR]	PROGRAM FILE ^("!SETTINGS[PROGRAM][PATH]!\!SETTINGS[PROGRAM][FILENAME]!"^) NOT FOUND^^!
	)
) ELSE (
	CALL :TIMESTAMP
	ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][ERROR]	CONFIGURATION FILE ^("%CONFIG_PATH%\%CONFIG_FILENAME%.%CONFIG_EXTENSION%"^) NOT FOUND^^!
)
GOTO END

REM Функция получения параметров коммандной строки:
:INIT
REM Перебираем в цикле все значения через пробел:
	FOR /F "tokens=1*" %%A IN ("%VARIABLE[INPUT][COMMAND_PARAMETERS]%") DO (
REM Присваиваем временной переменной текущее значение:
		SET VARIABLE[INPUT][TEMP]=%%A
REM Проверяем на совпадение начало строки параметра, если совпадение найдено, то присваиваем значение:
		IF /I "!VARIABLE[INPUT][TEMP]:~0,8!"=="--proxy=" SET VARIABLE[INPUT][PROXY]=!VARIABLE[INPUT][TEMP]:~8!
		IF /I "!VARIABLE[INPUT][TEMP]:~0,7!"=="--coin=" SET VARIABLE[INPUT][COIN]=!VARIABLE[INPUT][TEMP]:~7!
		IF /I "!VARIABLE[INPUT][TEMP]:~0,10!"=="--elevate=" SET VARIABLE[INPUT][ELEVATE]=!VARIABLE[INPUT][TEMP]:~10!
		SET VARIABLE[INPUT][TEMP]=
REM Если в строке еще что-то есть, повторяем цикл:
		IF "%%B" NEQ "" (
			SET VARIABLE[INPUT][COMMAND_PARAMETERS]=%%B
			CALL :INIT
		)
	)
GOTO END

REM Функция создания массива (списка) имен из всех указанных в конфигурации значений:
:CONFIG_ARRAY_LIST
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано):
	IF NOT DEFINED VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT] SET /A VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=%VARIABLE[CONFIG][ARRAY_LIST][COUNT][START]%
REM Разбор значений в случае если запрос относился к прокси:
	IF "%VARIABLE[CONFIG][ARRAY_LIST][TYPE]%" EQU "PROXY" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME] (
			IF %VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]% EQU 1 (
				CALL :TIMESTAMP
				ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][INFO]	LOADING %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% DATA...
			)
REM Если значение есть, выводим информацию и присваиваем его переменной:
			CALL :TIMESTAMP
			CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][INFO]		FOUND PROXY: "%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME]%%" ^("%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][ADDRESS]%%:%%SETTINGS[PROXY][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][PORT]%%"^)
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
				CALL :TIMESTAMP
				ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][INFO]	LOADING %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% DATA...
			)
REM Если значение есть, выводим информацию и присваиваем его переменной:
			CALL :TIMESTAMP
			CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][INFO]		FOUND POOL FOR COIN: "%%SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][COIN]%%" ^(NAME: "%%SETTINGS[POOL][%VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]%][NAME]%%"^)
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
		CALL :TIMESTAMP
		ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][ERROR]	NO ONE %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% FOUND IN CONFIGURATION^^!
	) ELSE (
		CALL :TIMESTAMP
		ECHO !VARIABLE[TIMESTAMP][VALUE]!	[CONFIG][INFO]	TOTAL %VARIABLE[CONFIG][ARRAY_LIST][TYPE]% FOUND IN CONFIGURATION: %VARIABLE[CONFIG][ARRAY_LIST][COUNT][TOTAL]%
	)
	SET VARIABLE[CONFIG][ARRAY_LIST][TYPE]=
	SET VARIABLE[CONFIG][ARRAY_LIST][COUNT][CURRENT]=
GOTO END

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

REM Функция проверки выбора ввода:
:CHECK
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано), задаем тип поиска и искомое значение:
	IF NOT DEFINED VARIABLE[CHECK][COUNT] (
		SET /A VARIABLE[CHECK][COUNT]=1
REM Проверяем параметр запуска функции и задаем необходимые переменные (если они не получены ранее):
		IF "%~1" EQU "PROXY" (
			SET VARIABLE[CHECK][TYPE]=PROXY
			SET VARIABLE[CHECK][VALUE_TEST]=%VARIABLE[INPUT][PROXY]%
		)
		IF "%~1" EQU "COIN" (
			SET VARIABLE[CHECK][TYPE]=COIN
			SET VARIABLE[CHECK][VALUE_TEST]=%VARIABLE[INPUT][COIN]%
		)
	)
	IF NOT DEFINED VARIABLE[CHECK][TYPE] GOTO :END
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
GOTO END
:CHECK_INPUT_SET_TRUE
	IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
REM Перебираем весь массив и проверяем, задано ли значение NAME:
		IF DEFINED SETTINGS[PROXY][%VARIABLE[CHECK][COUNT]%][NAME] (
REM Если значение есть, задаем его в переменной и проверяем дальше:
			CALL SET VARIABLE[CHECK][VALUE_CURRENT]=%%SETTINGS[PROXY][%VARIABLE[CHECK][COUNT]%][NAME]%%
			GOTO :CHECK_INPUT_SET_TRUE_DEFINED_TRUE
REM Если прошли весь массив значений монет, а выбранной записи так и не обнаружено:
		) ELSE (
REM Повторно пробуем задать значение или берем его из параметра по умолчанию:
			GOTO :CHECK_INPUT_SET_TRUE_DEFINED_FALSE
		)
	)
	IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
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
	)
GOTO END
:CHECK_INPUT_SET_TRUE_DEFINED_TRUE
REM Проверяем на свопадение текущего значения из массива и ранее заданного искомого:
	IF /I "%VARIABLE[CHECK][VALUE_CURRENT]%"=="%VARIABLE[CHECK][VALUE_TEST]%" (
REM Извещаем об успешном нахождении:
		IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][STATUS]	Selected "!VARIABLE[CHECK][VALUE_CURRENT]!" proxy.
		)
		IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][STATUS]	Selected "!VARIABLE[CHECK][VALUE_CURRENT]!" coin.
		)
REM Задаем искомое значение:
		SET VARIABLE[CHECK][VALUE]=%VARIABLE[CHECK][VALUE_CURRENT]%
REM Выходим:
		SET VARIABLE[CHECK][VALUE_CURRENT]=
		SET VARIABLE[CHECK][VALUE_TEST]=
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		GOTO :END
	) ELSE (
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[CHECK][COUNT]=%VARIABLE[CHECK][COUNT]% + 1
		SET VARIABLE[CHECK][VALUE_CURRENT]=
		GOTO :CHECK
	)
GOTO END
:CHECK_INPUT_SET_TRUE_DEFINED_FALSE
REM Если задана возможность ручного ввода данных:
	IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%"=="TRUE" (
REM Получаем значение из консоли:
		IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INPUT][ERROR]	Select "%VARIABLE[CHECK][VALUE_TEST]%" is not correct proxy. Please, try again...
			ECHO.
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
			CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
			SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a proxy !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		)
		IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INPUT][ERROR]	Select "%VARIABLE[CHECK][VALUE_TEST]%" is not correct coin. Please, try again...
			ECHO.
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
			CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
			SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a coin !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		)
REM Сбрасываем счетчик в начальное положение:
		SET /A VARIABLE[CHECK][COUNT]=1
REM Снова проходим тестирование на совпадение:
		GOTO :CHECK
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию:
	) ELSE (
		IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Selected "%VARIABLE[CHECK][VALUE_TEST]%" is not correct proxy. Default value ^("%SETTINGS[DEFAULT][PROXY]%"^) was set.
			SET VARIABLE[CHECK][VALUE]=%SETTINGS[DEFAULT][PROXY]%
		)
		IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Selected "%VARIABLE[CHECK][VALUE_TEST]%" is not correct coin. Default value ^("%SETTINGS[DEFAULT][COIN]%"^) was set.
			SET VARIABLE[CHECK][VALUE]=%SETTINGS[DEFAULT][COIN]%
		)
		ECHO.
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[CHECK][VALUE_TEST]=
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		GOTO :END
	)
GOTO END
:CHECK_INPUT_SET_FALSE
REM Если задана возможность ручного ввода данных:
	IF /I "%SETTINGS[DEFAULT][ALLOW_MANUAL_SELECT]%"=="TRUE" (
REM Получаем значение из консоли:
		IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
			CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
			SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a proxy !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		)
		IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
REM Формируем текст подсказки для выбора из доступных в конфигурации пунктов:
			CALL :CHECK_INPUT_TEXT_FORMAT "%VARIABLE[CHECK][TYPE]%"
			SET /P VARIABLE[CHECK][VALUE_TEST]="!VARIABLE[TIMESTAMP][VALUE]!	[INPUT]	Please select a coin !VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]!: "
		)
REM Сбрасываем счетчик в начальное положение:
		SET /A VARIABLE[CHECK][COUNT]=1
REM Снова проходим тестирование на совпадение:
		GOTO :CHECK
REM Если возможность ручного ввода запрещена, то берем значение по умолчанию:
	) ELSE (
		IF "%VARIABLE[CHECK][TYPE]%" EQU "PROXY" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Value for proxy not found. Default value ^("%SETTINGS[DEFAULT][PROXY]%"^) was set.
			SET VARIABLE[CHECK][VALUE]=%SETTINGS[DEFAULT][PROXY]%
		)
		IF "%VARIABLE[CHECK][TYPE]%" EQU "COIN" (
			CALL :TIMESTAMP
			ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Value for coin not found. Default value ^("%SETTINGS[DEFAULT][COIN]%"^) was set.
			SET VARIABLE[CHECK][VALUE]=%SETTINGS[DEFAULT][COIN]%
		)
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[CHECK][TYPE]=
		SET VARIABLE[CHECK][COUNT]=
		GOTO :END
	)
GOTO END
REM Функция формирования текста для подсказки выбора:
:CHECK_INPUT_TEXT_FORMAT
REM Определяем стартовое значение счетчика (если это первый проход и оно не задано), обнуляем на всякий случай значение результата и задаем тип поиска:
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT] (
		SET /A VARIABLE[CHECK][INPUT][TEXT_FORMAT][COUNT]=1
		SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=
		IF "%~1" EQU "PROXY" (
			SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=PROXY
		)
		IF "%~1" EQU "COIN" (
			SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE]=COIN
		)
	)
REM Проверяем параметр запуска функции и задаем необходимые переменные (если они не получены ранее):
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][TYPE] GOTO :END
REM Задаем начальное значение текста:
	IF NOT DEFINED VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE] SET VARIABLE[CHECK][INPUT][TEXT_FORMAT][VALUE]=[
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

REM Функция повышения прав через внутренний запуск VBS-скрипта:
:ELEVATE
REM Создаем скрипт-файл VBS со строкой запуска:
	ECHO CreateObject^("Shell.Application"^).ShellExecute "%~snx0","ELEVATE %~1","%~sdp0","runas","%PROGRAM_TITLE%">"%TEMP%\%PROGRAM_FILENAME%.vbs"
REM Запускаем созданный скрипт-файл:
	%CSCRIPT% //nologo "%TEMP%\%PROGRAM_FILENAME%.vbs"
REM Удаляем созданный скрипт-файл:
	IF EXIST "%TEMP%\%PROGRAM_FILENAME%.vbs" DEL "%TEMP%\%PROGRAM_FILENAME%.vbs"
GOTO END

REM Функция создания параметров коммандной строки для запуска программы:
:PARAMETERS
	CALL :PARAMETERS_PROXY_GET
	CALL :PARAMETERS_PROXY_TO_STRING
	CALL :PARAMETERS_POOL_GET
	CALL :PARAMETERS_POOL_TO_STRING
REM Добавляем в строку параметров для программы полученные данные по пулам:
	SET VARIABLE[PROGRAM][PARAMETERS]=%VARIABLE[PROGRAM][PARAMETERS]% %VARIABLE[PROGRAM][PARAMETERS][POOL][URL]% %VARIABLE[PROGRAM][PARAMETERS][POOL][USER]% %VARIABLE[PROGRAM][PARAMETERS][POOL][PASS]% %VARIABLE[PROGRAM][PARAMETERS][POOL][CUSTOM-DIFF]%
	SET VARIABLE[PROGRAM][PARAMETERS]=%VARIABLE[PROGRAM][PARAMETERS]% %VARIABLE[PROGRAM][PARAMETERS][PROXY]%
REM Добавляем в строку параметров для программы данные по умолчанию, указанные в конфигурации (если там что-то есть):
	IF "%SETTINGS[DEFAULT][PARAMETERS]%" NEQ "" SET VARIABLE[PROGRAM][PARAMETERS]=%VARIABLE[PROGRAM][PARAMETERS]% %SETTINGS[DEFAULT][PARAMETERS]%
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
REM Формируем строку параметров для программы по данным прокси:
	SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=--algo=%VARIABLE[PARAMETERS][PROXY][ALGORYTM]% --bind=%VARIABLE[PARAMETERS][PROXY][ADDRESS]%:%VARIABLE[PARAMETERS][PROXY][PORT]% --api-port=%VARIABLE[PARAMETERS][PROXY][API]% --api-access-token=%VARIABLE[PARAMETERS][PROXY][TOKEN]%
	IF "%VARIABLE[PARAMETERS][PROXY][NO-RESTRICTED]%" EQU "TRUE" SET VARIABLE[PROGRAM][PARAMETERS][PROXY]=%VARIABLE[PROGRAM][PARAMETERS][PROXY]% --api-no-restricted
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
			IF /I "!VARIABLE[PARAMETERS][POOL][CURRENT][ALGORYTM]!"=="%VARIABLE[PARAMETERS][PROXY][ALGORYTM]%" (
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
				CALL :TIMESTAMP
				CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Found correct pool ^("!VARIABLE[PARAMETERS][POOL][CURRENT][NAME]!"^) for "%VARIABLE[CHECK][VALUE][COIN]%" coin, but algorytm with proxy ^("%VARIABLE[PARAMETERS][PROXY][NAME]%"^) is different. Ignored.
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
		IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOL][URL] (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][URL]=--url=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][ADDRESS]%%:%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][PORT]%%
		) ELSE (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][URL]=%VARIABLE[PROGRAM][PARAMETERS][POOL][URL]% --url=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][ADDRESS]%%:%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][PORT]%%
		)
REM Параметры "DIFF", "ID", "EMAIL" и "WALLET" используются только от первого обнаруженного пула, все остальные параметры игнорируются и не задаются повторно:
REM Получаем значение WALLET для выбранного пула и присваиваем его переменной для удобства использования и проверок:
		CALL SET VARIABLE[PROGRAM][PARAMETERS][VALUE][WALLET]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][WALLET]%%
REM Получаем значение DIFF для выбранного пула и присваиваем его переменной для удобства использования и проверок:
		CALL SET VARIABLE[PROGRAM][PARAMETERS][VALUE][DIFF]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][DIFF]%%
REM Если значение блока "--user" не задано, то присваиваем ранее полученные значения:
		IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOL][USER] (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][USER]=--user=!VARIABLE[PROGRAM][PARAMETERS][VALUE][WALLET]!+!VARIABLE[PROGRAM][PARAMETERS][VALUE][DIFF]!
		) ELSE (
REM Если это уже не первый проход цикла, то есть пулов для данной монеты несколько, то проверяем на предмет повторов, если дубликат единого значения задан, выводим сообщение и игнорируем его:
			IF %VARIABLE[PARAMETERS][COUNT]% GTR 1 (
				IF "!VARIABLE[PROGRAM][PARAMETERS][VALUE][WALLET]!" NEQ "" (
					CALL :TIMESTAMP
					CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Duplicate parameter "WALLET" in configuration was set for coin "%VARIABLE[CHECK][VALUE][COIN]%" ^(for pool: "%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"^). Ignored.
				)
			)
		)
REM Если значение блока "--custom-diff" не задано, то присваиваем ранее полученное значение:
		IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOL][CUSTOM-DIFF] (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][CUSTOM-DIFF]=--custom-diff=!VARIABLE[PROGRAM][PARAMETERS][VALUE][DIFF]!
		) ELSE (
			IF %VARIABLE[PARAMETERS][COUNT]% GTR 1 (
REM Если это уже не первый проход цикла, то есть пулов для данной монеты несколько, то проверяем на предмет повторов, если дубликат единого значения задан, выводим сообщение и игнорируем его:
				IF "!VARIABLE[PROGRAM][PARAMETERS][VALUE][DIFF]!" NEQ "" (
					CALL :TIMESTAMP
					CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Duplicate parameter "DIFF" in configuration was set for coin "%VARIABLE[CHECK][VALUE][COIN]%" ^(for pool: "%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"^). Ignored.
				)
			)
		)
REM Получаем значение ID для выбранного пула и присваиваем его переменной для удобства использования и проверок:
		CALL SET VARIABLE[PROGRAM][PARAMETERS][VALUE][ID]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][ID]%%
REM Получаем значение EMAIL для выбранного пула и присваиваем его переменной для удобства использования и проверок:
		CALL SET VARIABLE[PROGRAM][PARAMETERS][VALUE][EMAIL]=%%VARIABLE[PARAMETERS][POOL][%VARIABLE[PARAMETERS][COUNT]%][EMAIL]%%
REM Если значение блока "--pass" не задано, то присваиваем ранее полученные значения:
		IF NOT DEFINED VARIABLE[PROGRAM][PARAMETERS][POOL][PASS] (
			CALL SET VARIABLE[PROGRAM][PARAMETERS][POOL][PASS]=--pass=!VARIABLE[PROGRAM][PARAMETERS][VALUE][ID]!:!VARIABLE[PROGRAM][PARAMETERS][VALUE][EMAIL]!
		) ELSE (
REM Если это уже не первый проход цикла, то есть пулов для данной монеты несколько, то проверяем на предмет повторов, если дубликат единого значения задан, выводим сообщение и игнорируем его:
			IF %VARIABLE[PARAMETERS][COUNT]% GTR 1 (
				IF "!VARIABLE[PROGRAM][PARAMETERS][VALUE][ID]!" NEQ "" (
					CALL :TIMESTAMP
					CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Duplicate parameter "ID" in configuration was set for coin "%VARIABLE[CHECK][VALUE][COIN]%" ^(for pool: "%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"^). Ignored.
				)
				IF "!VARIABLE[PROGRAM][PARAMETERS][VALUE][EMAIL]!" NEQ "" (
					CALL :TIMESTAMP
					CALL ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][ERROR]	Duplicate parameter "EMAIL" in configuration was set for coin "%VARIABLE[CHECK][VALUE][COIN]%" ^(for pool: "%%VARIABLE[PARAMETERS][POOL][!VARIABLE[PARAMETERS][COUNT]!][NAME]%%"^). Ignored.
				)
			)
		)
REM Увеличиваем значение счетчика и переходим в начало цикла:
		SET /A VARIABLE[PARAMETERS][COUNT]=%VARIABLE[PARAMETERS][COUNT]% + 1
		GOTO :PARAMETERS_POOL_TO_STRING
	) ELSE (
REM Сбрасываем счетчик и выходим:
		SET VARIABLE[PARAMETERS][COUNT]=
		GOTO :END
	)
GOTO END

REM Функция запуска программы с параметрами:
:START
REM Получаем проверенные значения выбора:
	CALL :CHECK "PROXY"
	SET VARIABLE[CHECK][VALUE][PROXY]=%VARIABLE[CHECK][VALUE]%
	CALL :CHECK "COIN"
	SET VARIABLE[CHECK][VALUE][COIN]=%VARIABLE[CHECK][VALUE]%
	ECHO.
REM Формируем строку параметров для запуска программы:
	CALL :PARAMETERS
	ECHO.
	CD "%SETTINGS[PROGRAM][PATH]%"
REM В заивисимости от того задано ли повышение прав до уровня Администратора или нет, запускаем программу разными методами (в отлельном окне, или в том же самом):
	IF "%~1" EQU "ELEVATE" (
		CALL :TIMESTAMP
		ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][STATUS]	Starting: "%SETTINGS[PROGRAM][PATH]%\%SETTINGS[PROGRAM][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS]%
		ECHO.
		CALL "%SETTINGS[PROGRAM][PATH]%\%SETTINGS[PROGRAM][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS]%
	) ELSE (
		CALL :TIMESTAMP
		ECHO !VARIABLE[TIMESTAMP][VALUE]!	[INFO][STATUS]	Starting: START "%SETTINGS[PROGRAM][TITLE]%" /D "%SETTINGS[PROGRAM][PATH]%" "%SETTINGS[PROGRAM][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS]%
		ECHO.
		START "%SETTINGS[PROGRAM][TITLE]%" /D "%SETTINGS[PROGRAM][PATH]%" "%SETTINGS[PROGRAM][FILENAME]%" %VARIABLE[PROGRAM][PARAMETERS]%
	)
GOTO END

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

:END
GOTO :EOF
