#define kSerialOffset    15
#define kIssueDateOffset 83
#define kExpDateOffset   98
#define kPublicKeyOffset 183
#define kCSRLength       522u

static uint8_t const kCertTemplate[783]={
0x30,0x82,0x03,0x0B,0x30,0x82,0x01,0xF3,0xA0,0x03,0x02,0x01,0x02,0x02,0x01,0x6A,
0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0B,0x05,0x00,0x30,
0x2E,0x31,0x1F,0x30,0x1D,0x06,0x03,0x55,0x04,0x03,0x0C,0x16,0x42,0x65,0x61,0x72,
0x64,0x69,0x65,0x20,0x43,0x6F,0x6E,0x74,0x72,0x6F,0x6C,0x20,0x53,0x65,0x72,0x76,
0x65,0x72,0x31,0x0B,0x30,0x09,0x06,0x03,0x55,0x04,0x06,0x13,0x02,0x55,0x53,0x30,
0x1E,0x17,0x0D,0x31,0x39,0x31,0x31,0x30,0x35,0x32,0x31,0x32,0x34,0x33,0x32,0x5A,
0x17,0x0D,0x31,0x39,0x31,0x32,0x30,0x35,0x32,0x31,0x32,0x34,0x33,0x32,0x5A,0x30,
0x2E,0x31,0x1F,0x30,0x1D,0x06,0x03,0x55,0x04,0x03,0x0C,0x16,0x42,0x65,0x61,0x72,
0x64,0x69,0x65,0x20,0x43,0x6F,0x6E,0x74,0x72,0x6F,0x6C,0x20,0x53,0x65,0x72,0x76,
0x65,0x72,0x31,0x0B,0x30,0x09,0x06,0x03,0x55,0x04,0x06,0x13,0x02,0x55,0x53,0x30,
0x82,0x01,0x22,0x30,0x0D,0x06,0x09,0x2A,0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x01,
0x05,0x00,0x03,0x82,0x01,0x0F,0x00,0x30,0x82,0x01,0x0A,0x02,0x82,0x01,0x01,0x00,
0xE4,0xBB,0x22,0xBF,0x9C,0x77,0x6D,0x89,0xE8,0xD6,0xC1,0x60,0xF6,0x81,0xF3,0xF8,
0x19,0xA6,0xF2,0x22,0x39,0x10,0x0E,0xF7,0xB1,0xBE,0x01,0x99,0xC6,0x70,0x0E,0xC5,
0x75,0x26,0x78,0xDE,0x78,0xD3,0xAE,0x49,0x4B,0x76,0x3C,0x7C,0xCF,0x35,0x5E,0x70,
0x8C,0x5E,0x74,0x1D,0x74,0x43,0x81,0xF0,0x35,0xD4,0xDC,0x38,0xEB,0xCC,0x52,0xBB,
0xCA,0xDA,0xBB,0x4D,0x3F,0xF5,0xE6,0x68,0xC2,0x76,0xE9,0xA9,0x78,0x0A,0x1C,0xB7,
0x8A,0x1E,0x5C,0xF1,0x03,0xA8,0x1F,0x25,0x60,0x6C,0xAF,0x53,0xC0,0x3A,0x61,0x8D,
0xB6,0x6A,0x15,0x3E,0x09,0x6A,0xFF,0xCB,0x7D,0x67,0xE7,0xAF,0x5E,0x8B,0xAA,0xE4,
0x86,0x6D,0x03,0x4C,0x63,0x60,0x40,0xC6,0x90,0x32,0x3B,0x75,0x58,0xE8,0x71,0x2E,
0xFB,0x04,0xDA,0xFC,0x79,0x62,0x61,0x40,0x39,0xB5,0x38,0x63,0x81,0x9A,0x18,0x78,
0xEE,0x93,0x16,0x37,0x0A,0x48,0x62,0xF2,0x6F,0x6A,0xB3,0x3B,0x73,0x9B,0x7E,0xF0,
0x2D,0x64,0x84,0x9D,0xF4,0x39,0x0E,0xB5,0xC1,0x2E,0x5F,0x18,0xA0,0x82,0x95,0x9D,
0x0A,0x32,0x58,0x6E,0xCC,0x3F,0x8C,0x2E,0xB4,0x15,0x43,0x7C,0xF9,0x34,0xFE,0x2C,
0xC6,0x3F,0x82,0x6A,0x78,0x32,0x4F,0xD4,0x49,0xE8,0x9C,0xF9,0x43,0xC5,0xD6,0x04,
0xD8,0x83,0xF1,0xDF,0x67,0x0C,0x6E,0x7B,0x9C,0xD7,0x43,0x3E,0x56,0xBA,0xC2,0x3D,
0x04,0x01,0x06,0xB2,0xCE,0x2D,0x94,0xA2,0x6B,0x00,0xA2,0xCC,0xEE,0xED,0x02,0xD8,
0x37,0x2B,0x1E,0x53,0x1E,0x15,0x08,0x0C,0xF0,0x72,0x0D,0xE1,0x47,0x8C,0xA9,0xBD,
0x02,0x03,0x01,0x00,0x01,0xA3,0x34,0x30,0x32,0x30,0x0E,0x06,0x03,0x55,0x1D,0x0F,
0x01,0x01,0xFF,0x04,0x04,0x03,0x02,0x07,0x80,0x30,0x20,0x06,0x03,0x55,0x1D,0x25,
0x01,0x01,0xFF,0x04,0x16,0x30,0x14,0x06,0x08,0x2B,0x06,0x01,0x05,0x05,0x07,0x03,
0x02,0x06,0x08,0x2B,0x06,0x01,0x05,0x05,0x07,0x03,0x01,0x30,0x0D,0x06,0x09,0x2A,
0x86,0x48,0x86,0xF7,0x0D,0x01,0x01,0x0B,0x05,0x00,0x03,0x82,0x01,0x01,0x00,0xA8,
0xF2,0xA6,0x28,0x49,0xCF,0x2A,0x8F,0x6A,0x5A,0xA2,0x42,0xF6,0xD5,0x51,0x61,0x92,
0xFE,0x85,0x22,0x0C,0x18,0x71,0x31,0x03,0xE4,0xE1,0xEA,0xEF,0x2E,0xB5,0x34,0x46,
0xD6,0x58,0xCB,0xA4,0x35,0xAD,0xE8,0x3E,0x3C,0xFB,0x56,0x6B,0x92,0x6D,0x84,0xF2,
0xF0,0xF3,0x21,0x54,0x8D,0x1F,0xA7,0x40,0x35,0x29,0x01,0x51,0x36,0xBF,0x8C,0xA7,
0xD5,0x13,0xE2,0xB3,0xBB,0x57,0x90,0x35,0x51,0xA4,0xCE,0xB5,0xD6,0x61,0x56,0x2B,
0x1F,0x69,0xA4,0x7A,0xF5,0x34,0xA9,0x0E,0x81,0xEB,0x67,0x72,0x69,0x94,0x03,0x33,
0x19,0xE1,0xCE,0xA3,0x4A,0xDC,0xF5,0x89,0x1D,0x9C,0xAE,0xC3,0x8B,0x30,0xFA,0x31,
0xC4,0x6C,0x51,0x30,0x06,0x00,0x3B,0x5D,0x10,0xD4,0x68,0xE1,0x10,0xE2,0x96,0x23,
0xEF,0x1F,0x86,0x71,0x77,0x76,0x06,0xED,0xAC,0x02,0x0C,0x50,0x0B,0xEE,0xE9,0xDC,
0x0A,0x3E,0x1A,0xA2,0xA1,0x76,0x3B,0xAF,0xA9,0x54,0x00,0x34,0x59,0x52,0xB8,0x40,
0x1C,0x60,0x28,0x41,0x65,0xD3,0xFC,0x22,0xF9,0x99,0x97,0xC6,0xE7,0xDB,0xCB,0x91,
0xCD,0xAC,0x13,0xED,0xA3,0xFA,0x6C,0x31,0x00,0xCD,0x94,0xEC,0x2F,0x84,0x41,0xA8,
0x53,0xDA,0x30,0xC3,0x30,0x6D,0x1F,0x79,0xB8,0x51,0x2F,0xDD,0x59,0xC9,0x8A,0x1D,
0x6D,0xC5,0xB6,0x24,0xE1,0xEE,0xEA,0x7E,0x89,0x3E,0x10,0x23,0xE0,0x73,0xBF,0x8A,
0xCD,0x9A,0x46,0x70,0xBE,0xD6,0x39,0x61,0x33,0xDD,0xD5,0xAB,0x31,0x11,0xA0,0x1B,
0xE5,0x4A,0x7C,0x65,0x3A,0xF9,0x13,0x33,0xCC,0xA0,0x4A,0x74,0x71,0xB3,0x79,
};
