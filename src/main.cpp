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
	int uart_port = -1;
	bool is_default = false;
	UartPinAssignment pin_assignment;
	Thread input_thread(2048, false);

	u32 o_flags;
	int freq = 115200;
	int width = 8;

	o_flags = Uart::FLAG_SET_CONTROL_LINE_STATE;

	if( cli.is_option("-p") ){
		uart_port = cli.get_option_value("-p");
	} else {
		printf("Error: must specify UART port using -p option\n");
		show_usage();
		exit(1);
	}

	if( cli.is_option("-default") ){
		is_default = true;
	}

	if( cli.is_option("-f") ){
		freq = cli.get_option_value("-f");
	}

	if( cli.is_option("-w") ){
		width = cli.get_option_value("-w");
	}

	if( cli.is_option("-rx") ){
		pin_assignment->rx = cli.get_option_pin("-rx");
	}

	if( cli.is_option("-tx") ){
		pin_assignment->tx = cli.get_option_pin("-tx");
	}

	if( cli.is_option("-even") ){
		o_flags |= Uart::FLAG_IS_PARITY_EVEN;
	} else if( cli.is_option("-odd") ){
		o_flags |= Uart::FLAG_IS_PARITY_ODD;
	} else {
		o_flags |= Uart::FLAG_IS_PARITY_NONE;
	}

	Uart uart(uart_port);
	if( uart.open(Uart::NONBLOCK) < 0 ){
		printf("Failed to open UART port %d\n", uart_port);
		perror("Failed");
		exit(1);
	}

	if( is_default ){
		if( uart.set_attr() < 0 ){
			printf("Uart does not have a default configuration\n");
			exit(1);
		}
	} else {
		if( uart.set_attr(o_flags, freq, width, pin_assignment) < 0 ){
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
		}
		Timer::wait_msec(1);
	} while( !m_stop );

	return 0;
}


void show_usage(){
	printf("Usage:\n");
}
