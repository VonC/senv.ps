@echo off
go test|grep -v -e "^\..*"|grep -v "^$"|grep -v "thus far"
