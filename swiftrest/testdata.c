//
//  bla.c
//  swiftrest
//
//  Created by Steffen Neubauer on 16/06/15.
//  Copyright © 2015 Steffen Neubauer. All rights reserved.
//

#include "testdata.h"

char* return_test_data(void) {
    return "POST / HTTP/1.1\nHost: google.com\nContent-Type:text/text\nContent-Length:5\n\nHallo";
};
size_t return_test_length(void) {
    return 79;
};