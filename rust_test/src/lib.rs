use core::sync::atomic::spin_loop_hint;
use std::ptr::write_volatile;

const BASIC_INIT_STUB_SIZE: u16 = 12;
const ENTRY_ADDRESS: u16 = 0x0801 + BASIC_INIT_STUB_SIZE;

#[link_section = ".basic_stub"]
#[no_mangle]
static BASIC_INIT_STUB: [u8; BASIC_INIT_STUB_SIZE as usize] = [
    0x0b,
    0x08,
    0xe3,
    0x07,
    0x9e,
    (ENTRY_ADDRESS % 10000 / 1000) as u8,
    (ENTRY_ADDRESS % 1000 / 100) as u8,
    (ENTRY_ADDRESS % 100 / 10) as u8,
    (ENTRY_ADDRESS % 10) as u8,
    0x00,
    0x00,
    0x00,
];

macro_rules! const_address{
    ($name:ident = $value:expr) => {
        const $name: *mut u8 = $value as _;
    };
}

const_address!(SCREENRAM = 0x0400);
const_address!(SCREENRAM_1 = 0x0500);
const_address!(SCREENRAM_2 = 0x0600);
const_address!(SCREENRAM_3 = 0x0700);

unsafe fn clear() {
    let value = 0x20;
    for _ in 0u8..255 {
        write_volatile(SCREENRAM, value);
        write_volatile(SCREENRAM_1, value);
        write_volatile(SCREENRAM_2, value);
        write_volatile(SCREENRAM_3, value);
    }
}

const_address!(VOLUME = 0xd418);
const_address!(VOICE_1_FREQ_LOW = 0xd400);
const_address!(VOICE_1_FREQ_HIGH = 0xd401);
const_address!(VOICE_1_CTRL = 0xd404);
const_address!(VOICE_1_ATTACK_DECAY = 0xd405);
const_address!(VOICE_1_SUSTAIN_RELEASE = 0xd406);

unsafe fn make_sound() {
    //c64::sei();

    write_volatile(VOLUME, 0x0f);

    write_volatile(VOICE_1_ATTACK_DECAY, 0x61);
    write_volatile(VOICE_1_SUSTAIN_RELEASE, 0xc8);
    
    write_volatile(VOICE_1_FREQ_LOW, 0x34);
    write_volatile(VOICE_1_FREQ_HIGH, 0x10);
    
    write_volatile(VOICE_1_CTRL, 0x21);

    for _ in 0u16..65535 {
        spin_loop_hint();
    }

    write_volatile(VOICE_1_CTRL, 0x20);

    //c64::cli();
}

const_address!(BGCOLOR = 0xd020);
const_address!(BORDERCOLOR = 0xd021);

#[link_section = ".entry"]
#[no_mangle]
pub fn entry() {
    unsafe {
        let value = 0x06;
        write_volatile(BGCOLOR, value);
        write_volatile(BORDERCOLOR, value);

        clear();
        make_sound();

        let mut index: u8 = 0;

        for c in HELLO {
            write_volatile(SCREENRAM.offset(index as isize), *c);
            index += 1;
        }

        loop {}
    }
}

static HELLO: &[u8] = b"hello world!\0";
