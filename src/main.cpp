/*

Copyright 2011-2017 Tyler Gilbert

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

 */

#include <cstdio>
#include <sapi/sys.hpp>
#include <sapi/var.hpp>
#include <sapi/hal.hpp>


static volatile bool m_stop;

static void show_usage();
static void * process_uart_input(void * args);

int main(int argc, char * argv[]) {
	String input;
	Cli cli(argc, argv);
	cli.set_publisher("Stratify Labs, Inc");
	cli.handle_version();
	bool is_default = false;
	UartAttr uart_attr;
	Thread input_thread(2048, false);

	if( cli.handle_uart(uart_attr) == false ) {
		show_usage();
		exit(1);
	}

	if( cli.is_option("-default") ){
		is_default = true;
	}

	Uart uart(uart_attr.port());
	if( uart.open(Uart::RDWR) < 0 ){
		printf("Failed to open UART port %d\n", uart_attr.port());
		perror("Failed");
		exit(1);
	}

	if( is_default ){
		printf("Starting Uart probe on port %d with default settings\n", uart_attr.port());
		if( uart.set_attr() < 0 ){
			printf("Uart does not have a default configuration\n");
			exit(1);
		}
	} else {
		printf("Starting Uart probe on port %d at %ldbps\n", uart_attr.port(), uart_attr.freq());
		if( uart.set_attr(uart_attr) < 0 ){
			printf("Failed to configure UART\n");
			perror("Failed\n");
			exit(1);
		}
	}

	input_thread.create(process_uart_input, &uart);

	do {
		input.clear();
		fgets(input.cdata(), input.capacity(), stdin);
		if( input != "exit\n" ){ uart.write(input); }
	} while( input != "exit\n" );

	printf("Stopping\n");
	m_stop = true;

	input_thread.kill(Signal::CONT); //this will interrupt the blocking UART read and cause m_stop to be read
	input_thread.join(); //this will suspend until input_thread is finished


	printf("Closing UART\n");
	uart.close();

	printf("Exiting\n");

	return 0;
}

void * process_uart_input(void * args){
	Uart * uart = (Uart*)args;
	String input;
	do {
		input.clear();
		if( uart->read(input.cdata(), input.capacity()) > 0 ){
			input.printf();
			fflush(stdout);
		}
	} while( !m_stop );

	return 0;
}


void show_usage(){
	printf("Usage:\tuartprobe -p port [-f bitrate] [-tx X.Y -rx X.Y] [-even] [-odd] [-default] \n");
	printf("Default settings are 115200,8,n,1\n");
}
