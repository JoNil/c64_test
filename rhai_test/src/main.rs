use std::error::Error;
use rhai::Engine;

fn main() -> Result<(), Box<dyn Error>> {
    let engine = Engine::new();

    let ast = engine.compile(
r#"

    const BGCOLOR = $d020;
    const BORDERCOLOR = $d021;
    let a = 6;

    //*BGCOLOR = a;
    //*BORDERCOLOR = a;

    
"#)?;

    println!("{:?}", &ast);

    Ok(())
}
