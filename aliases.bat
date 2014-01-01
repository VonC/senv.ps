doskey cdhugo=cd %PROG%\go\src\github.com\spf13\hugo
doskey cdhugot=cd %PROG%\hugo\test
doskey cdjazz=cd %PROG%\go\src\oslc\jazz
doskey cdgit=cd %PROG%\git\git

set GFW="%LOCALAPPDATA%\GitHub\GitHub.appref-ms"
doskey g4w=%GFW% $*

doskey gocov=go test -coverprofile=coverage.out^&^&go tool cover -html=coverage.out ; doskey /exename=gocov gocov=go test -coverprofile=coverage.out^&^&go tool cover -html=coverage.out