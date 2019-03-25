with Ada.Text_IO;
with Ada.Real_Time;
use type Ada.Real_Time.Time;
use type Ada.Real_Time.Time_Span;
with BBS.embed.due.serial.polled;
with BBS.embed.due.serial.int;
with BBS.embed.GPIO.Due;
with BBS.embed.due.GPIO;
with utils;
with analogs;
with cli;
with bbs.embed.i2c.due;
use type bbs.embed.i2c.err_code;
with BBS.embed.log;

procedure Main is
   stdout  : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.init(0, 115_200);
   stdin   : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.get_port(0);
   serial1 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.init(1, 115_200);
   serial2 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.init(2, 115_200);
   serial3 : constant BBS.embed.due.serial.int.serial_port := BBS.embed.due.serial.int.init(3, 115_200);
   i2c_0   : aliased bbs.embed.i2c.due.due_i2c_interface := bbs.embed.i2c.due.get_interface(0);
   i2c_1   : aliased bbs.embed.i2c.due.due_i2c_interface := bbs.embed.i2c.due.get_interface(1);
   RS485_pin : BBS.embed.GPIO.Due.Due_GPIO_ptr := BBS.embed.due.GPIO.pin22;

begin
   stdout.put_line("Central Control Computer starting up:");
   stdout.put_line("Configuing Logging.");
   utils.dbg.enable;
   utils.err.enable;
   utils.info.enable;
   BBS.embed.log.debug := utils.dbg'Access;
   BBS.embed.log.error := utils.err'Access;
   BBS.embed.log.info  := utils.info'Access;
   if cli.analog_enable then
      stdout.put_line("Analogs: Setting up inputs");
      analogs.setup_ain;
      stdout.put_line("Analogs: Enabling inputs");
      for i in analogs.AIN_Num'Range loop
         analogs.enable_ain(i, True);
      end loop;
      stdout.put_line("Analogs: Free run");
      analogs.free_run(True);
      stdout.put_line("Analogs: Setting up outputs");
      analogs.setup_aout;
      stdout.put_line("Analogs: Enabling outputs");
      analogs.enable_aout(0, True);
      analogs.enable_aout(1, True);
   else
      stdout.put_line("Analogs: Disabled");
   end if;
   --
   --  I2C device initialization
   --
   if cli.i2c_enable then
      stdout.put_line("I2C: Initialization");
      bbs.embed.i2c.due.init(0, bbs.embed.i2c.due.low100);
      bbs.embed.i2c.due.init(1, bbs.embed.i2c.due.low100);
      cli.i2c_probe(0);
      cli.i2c_probe(1);
   else
      stdout.put_line("I2C: Disabled.");
   end if;
   --
   --  Other initializations
   --
   stdout.put_line("GPIO: Configuing RS485 control pin");
   RS485_pin.config(BBS.embed.GPIO.Due.gpio_output);
   RS485_pin.set(0);
   stdout.put_line("Serial: Enabling RS485 control on serial 1");
   serial1.enable_rs485(RS485_pin);
   stdout.put_line("LED: Starting LED flashing task");
   utils.ctrl_flasher(True);
   stdout.put_line("Serial: Enable receive on stdin");
   stdin.rx_enable(True);
   stdout.put_line("BOOT: Setup complete.");
   --
   --  Initializations complete, start the CLI loop.
   --
   loop
      cli.logon;
      cli.command_loop;
   end loop;
end Main;
