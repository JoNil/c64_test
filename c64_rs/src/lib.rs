#![no_std]

#[link_section = ".basic"]
#[no_mangle]
pub static BASIC_BYTES: [u8; 8] = [
    0x0b, 0x08,
    0xe3,
    0x07, 0x9e,
    (0x8009 % 10000 / 1000) as u8,
    (0x8009 % 1000 / 100) as u8,
    (0x8009 % 10) as u8,
];

const SCREENRAM: *mut u8 = 0x0400 as *mut _;
const SCREENRAM_1: *mut u8 = 0x0500 as *mut _;
const SCREENRAM_2: *mut u8 = 0x0600 as *mut _;
const SCREENRAM_3: *mut u8 = 0x0700 as *mut _;

unsafe fn clear() {
    let v = 0x20;
    for _i in 0..255 {
        *SCREENRAM = v;
        *SCREENRAM_1 = v;
        *SCREENRAM_2 = v;
        *SCREENRAM_3 = v;
    }
}

const VOLUME: *mut u8 = 0xd418 as *mut _;
const VOICE_1_FREQ_LOW: *mut u8 = 0xd400 as *mut _;
const VOICE_1_FREQ_HIGH: *mut u8 = 0xd401 as *mut _;
const VOICE_1_CTRL: *mut u8 = 0xd404 as *mut _;
const VOICE_1_ATTACK_DECAY: *mut u8 = 0xd405 as *mut _;
const VOICE_1_SUSTAIN_RELEASE: *mut u8 = 0xd406 as *mut _;

unsafe fn make_sound() {
    //c64::disable_interupts();

    *VOLUME = 0x0f;

    *VOICE_1_ATTACK_DECAY = 0x61;
    *VOICE_1_SUSTAIN_RELEASE = 0xc8;
    
    *VOICE_1_FREQ_LOW = 0x34;
    *VOICE_1_FREQ_HIGH = 0x10;
    
    *VOICE_1_CTRL = 0x21;

    for _i in 0..65535 {}

    *VOICE_1_CTRL = 0x20;

    //c64::enable_interupts();
}

const BGCOLOR: *mut u8 = 0xd020 as *mut _;
const BORDERCOLOR: *mut u8 = 0xd021 as *mut _;

#[link_section = ".entry"]
#[no_mangle]
unsafe extern "C" fn entry() {

    let color = 0x06;
    *BGCOLOR = color;
    *BORDERCOLOR = color;

    clear();
    make_sound();

    for (i, c) in ENTRY_HELLO.iter().enumerate() {
        *SCREENRAM.offset(i as isize) = *c;
    }

    loop {}
}

const ENTRY_HELLO: &[u8] = b"hello world!\0";