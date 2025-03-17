FROM step1:latest

# Check that random.txt exists, otherwise fail
RUN test -f /random.txt

# Print the content of the variable
CMD ["sh", "-c", "echo [random.txt]: $(cat /random.txt)"]
