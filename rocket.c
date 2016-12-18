/*
 *  Bill Foote, http://jovial.com
 *
 *  Control a Griffin RocketFM transmitter.
 *  Adapted from the rocket.c I found at http://tipok.org.ua/node/9
 *
 *
 * compile with:
     gcc -g -o rocket rocket.c -lhidapi-libusb
     chmod 111 rocket
     chown root rocket
     chmod u+s rocket
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <hidapi/hidapi.h>

#define ROCKET_VENDID 0x077d    /* Griffin's Vendor ID */
#define ROCKET_DEVID 0x0503     /* The RocketFM's Device ID */
#define SEND_PACKET_LENGTH 6    /* size of an instruction packet: rocketfm=6 */

#define DEBUG 1			/* Set true for copious debugging output */


void usage(int argc, const char** argv) {
    printf("\n");
    printf("%s -freq <freqeuncy> [-m]\n\tchange state of RocketFM\n\n", 
           argv[0]);
    printf("    commands:\n"
      "     -freq <freqeuncy>  : set TX frequency, e.g. '-freq 91.5'\n"
      "     -m                 : mono (default is stereo)\n");
    printf("\n");
    printf("%s -enumerate  : see USB devices\n", argv[0]);
    printf("\n");
    printf("Valid FM frequencies are 88.1 to 107.9 MHz in the US, but\n");
    printf("according to http://tipok.org.ua/node/9 , this device will\n");
    printf("work anywhere from 70 to 120 MHz.\n");
    printf("\n");
    exit(1);
}

void enumerate() {
    int res;
    unsigned char buf[65];
    #define MAX_STR 255
    wchar_t wstr[MAX_STR];
    hid_device *handle;
    int i;

    // Enumerate and print the HID devices on the system
    struct hid_device_info *devs, *cur_dev;
    
    devs = hid_enumerate(0x0, 0x0);
    cur_dev = devs; 
    while (cur_dev) {
        printf("Device Found\n  type: %04hx %04hx\n  path: %s\n  serial_number: %ls",
            cur_dev->vendor_id, cur_dev->product_id, cur_dev->path, cur_dev->serial_number);
        printf("\n");
        printf("  Manufacturer: %ls\n", cur_dev->manufacturer_string);
        printf("  Product:      %ls\n", cur_dev->product_string);
        printf("\n");
        cur_dev = cur_dev->next;
    }
    hid_free_enumeration(devs);
}




void set(unsigned char send_packet[], size_t send_packet_length) {
    int res;
    unsigned char buf[65];
    #define MAX_STR 255
    wchar_t wstr[MAX_STR];
    hid_device *handle;
    int i;

    i = hid_init();
    if (i != 0) {
        fprintf(stderr, "hid_init failed with return code %d\n", i);
	exit(1);
    }

    // Open the device using the VID, PID,
    // and optionally the Serial number.
    handle = hid_open(ROCKET_VENDID, ROCKET_DEVID, NULL);

    if (!handle) {
	printf("\n");
        printf("Error:  Unable to open rocket device.  Null handle.\n");
	printf("        Looking for vendor id %04hx, device ID %04hx.\n",
		ROCKET_VENDID, ROCKET_DEVID);
	printf("\n");
	printf("Is suid set?\n\n");
	exit(1);
    }

    // Read the Manufacturer String
    res = hid_get_manufacturer_string(handle, wstr, MAX_STR);
    printf("Manufacturer String: %ls\n", wstr);

    // Read the Product String
    res = hid_get_product_string(handle, wstr, MAX_STR);
    printf("Product String: %ls\n", wstr);

    // Read the Serial Number String
    res = hid_get_serial_number_string(handle, wstr, MAX_STR);
    printf("Serial Number String: %ls", wstr);
    printf("\n");

    i = hid_write(handle, send_packet, send_packet_length);
    printf("Wrote %d bytes (expecting %d)\n", 
    	   (int) i, (int) send_packet_length);

    if (i != send_packet_length) {
        printf("\n");
        printf("Error:  Unable to send packet to rocket\n");
	printf("        %S\n", hid_error(handle));
        printf("\n");
        exit(1);
    }

    hid_close(handle);

    i = hid_exit();
    if (i != 0) {
	printf("\n");
	printf("Warning:  hid_exit gave unexpected return code %d.\n", i);
	printf("\n");
    }
}

int main(int argc, const char** argv) {
    /* Build the instruction packet to send to the rocket */
    unsigned char PACKET[SEND_PACKET_LENGTH] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    unsigned char power = 0x01;
    unsigned short encodedFreq;
    float freq;
    unsigned short stereo;

    if (argc == 3 || (argc == 4 && strcmp(argv[3], "-m") == 0)) {
        if (strcmp(argv[1], "-freq") == 0) {
            /* Setup FM transmitting frequency */
            PACKET[0] = 0xC0;
            freq = atof(argv[2]);
            encodedFreq  = freq * 10;
            
            if ( (argc == 4) && strcmp(argv[3], "-m") == 0) {
                PACKET[1] = ((encodedFreq >> 8) & 0x07) | 0x40; /* Stereo - OFF  */
            } else {
                PACKET[1] = ((encodedFreq >> 8) & 0x07) | 0x48; /* By default, stereo turned ON */          
            }
            
            PACKET[2] = encodedFreq & 0xFF;
            PACKET[3] = ~(2 * power + 1) & 0x0F;
            PACKET[4] = 0x00;
            PACKET[5] = 0x00;
            if (DEBUG) {
                printf("fm freq = %.1f\n", freq);
                printf("encoded freq = 0x%x\n", (unsigned int)encodedFreq);
                printf("packet = 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x 0x%02x\n", PACKET[0], PACKET[1], PACKET[2], PACKET[3], PACKET[4], PACKET[5]);
            }
	    set(PACKET, SEND_PACKET_LENGTH);
        } else {
            /* Bad command - display the program's usage instructions */
            usage(argc, argv);
        }
    } else if (argc == 2 && strcmp("-enumerate", argv[1]) == 0) {
        enumerate();
    } else {
        usage(argc, argv);
    }
    exit(0);
}
