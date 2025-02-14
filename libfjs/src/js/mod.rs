use tokio::io::AsyncReadExt;
mod console;
mod fetch;
mod value;

pub fn setup_basics(ctx: &rquickjs::Ctx) -> anyhow::Result<()> {
    console::setup_console(ctx)?;
    fetch::setup_fetch(ctx)?;
    Ok(())
}
