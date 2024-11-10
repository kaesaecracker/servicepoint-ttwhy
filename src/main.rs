use clap::Parser;
use servicepoint::cp437::char_to_cp437;
use servicepoint::{
    CharGrid, Command, Connection, Cp437Grid, DataRef, Grid, Origin, FRAME_PACING, TILE_HEIGHT,
    TILE_WIDTH,
};
use std::io::Read;
use std::thread::sleep;

#[derive(Parser, Debug)]
struct Args {
    #[arg(
        short,
        long,
        default_value = "localhost:2342",
        help = "Address of the display"
    )]
    destination: String,
}

struct App {
    connection: Connection,
    mirror: CharGrid,
    x: usize,
    y: usize,
}

impl App {
    fn new(connection: Connection) -> Self {
        Self {
            connection,
            mirror: CharGrid::new(TILE_WIDTH, TILE_HEIGHT),
            x: 0,
            y: 0,
        }
    }

    fn run(&mut self) {
        for byte in std::io::stdin().bytes() {
            let byte = match byte {
                Err(err) => {
                    panic!("could not read from stdin: {}", err)
                }
                Ok(val) => val,
            };

            let char = byte as char;
            self.handle_char(char);
        }
    }

    fn shift_rows(&mut self) {
        let data = self.mirror.data_ref_mut();
        data.rotate_left(TILE_WIDTH);
        data.last_chunk_mut()
            .map(move |row: &mut [char; TILE_WIDTH]| row.fill(' '));
    }

    fn handle_char(&mut self, char: char) {
        match char {
            '\n' => self.handle_newline(),
            char => {
                if self.x < self.mirror.width() {
                    self.mirror.set(self.x, self.y, char);

                    let grid = Cp437Grid::load(1, 1, &[char_to_cp437(char)]);
                    self.connection
                        .send(Command::Cp437Data(Origin::new(self.x, self.y), grid))
                        .unwrap();
                    sleep(FRAME_PACING);
                }

                self.x += 1;
            }
        }
    }

    fn handle_newline(&mut self) {
        self.x = 0;
        if self.y + 1 == self.mirror.height() {
            self.shift_rows();
            self.send_mirror();
        } else {
            self.y += 1;
        }
    }

    fn send_mirror(&self) {
        self.connection
            .send(Command::Cp437Data(
                Origin::ZERO,
                Cp437Grid::from(&self.mirror),
            ))
            .unwrap();
        sleep(FRAME_PACING);
    }
}

fn main() {
    let args = Args::parse();
    let connection = Connection::open(&args.destination).unwrap();
    connection.send(Command::Clear).unwrap();
    App::new(connection).run()
}
