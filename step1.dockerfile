FROM alpine:latest

# Create a file containing a randomly generated string
RUN echo "This is a random string: $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')" > /random.txt

# Print the contents of the file
CMD ["cat", "/random.txt"]
