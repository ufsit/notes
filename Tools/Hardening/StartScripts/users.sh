#!/bin/bash
# Currently in
echo -e "\e[32mUsers currently logged in:\e[0m"
who

#Prints out any users with ability to run commands
echo -e "\e[33mUsers that can run commands:\e[0m"
cat /etc/passwd | grep "sh$"

echo -e "\e[31mDon't forget, change your passwords!!!\e[0m"

