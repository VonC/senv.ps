if "%1"=="" goto end
if "%2"=="" goto have_1
if "%3"=="" goto have_2
:have_1
grep -nrHI "%1" *
goto end
:have_2
grep -nrHI "%1" * | grep %2
:end
