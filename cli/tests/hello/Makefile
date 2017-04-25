all: hello

clean:
	rm -f hello

hello: Makefile hello.c
	$(CC)gcc hello.c -o hello -DENV_NAME=\"${HOSTNAME}\"
