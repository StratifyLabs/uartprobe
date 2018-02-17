import QtQuick 2.0
import StratifyLabs.UI 2.1
import QtCharts 2.2
import QtQuick.Dialogs 1.2


SContainer {
  name: "Test";
  style: "block fill";

  function startProgramming(){
    var args = "-uart " + uartPort.text +
        " -r " + resetPin.text +
        " -b0 " + boot0Pin.text +
        (boot1Pin.text ? " -b1 " + boot1Pin.text : "") +
        (rxPin.text ? " -rx " + rxPin.text : "") +
        (txPin.text ? " -tx " + txPin.text : "") +
        (bitrate.text ? " -f " + bitrate.text : "") +
        " -i " + "/home/" + imageFile.text.split('/').pop();

    logic.runApp("stm32prog " + args);
    logic.setState("stm32prog.binaryImage", imageFile.text);
    logic.setState("stm32prog.uartPort", uartPort.text);
    logic.setState("stm32prog.resetPin", resetPin.text);
    logic.setState("stm32prog.boot0Pin", boot0Pin.text);
    logic.setState("stm32prog.boot1Pin", boot1Pin.text);
    logic.setState("stm32prog.bitrate", bitrate.text);
    logic.setState("stm32prog.rxPin", rxPin.text);
    logic.setState("stm32prog.txPin", txPin.text);
    console.log("Run stm32prog " + args);
  }

  Connections {
    target: logic;
    onCopyFileToDeviceCompleted: {
      console.log("File Copy Complete: Run App");


      if( logic.isAppRunning("uartprobe") ){
        logic.killApp("uartprobe");
      } else {
        startProgramming();
      }
    }

    onAppStopped: {
      if( name === "stm32prog" ){
        logic.runApp("uartprobe -p " + uartPort.text);
      }

      if( name === "uartprobe" ){
        startProgramming();
      }
    }
  }


  Component.onCompleted: {
    imageFile.text = logic.getState("stm32prog.binaryImage");
    uartPort.text = logic.getState("stm32prog.uartPort");
    resetPin.text = logic.getState("stm32prog.resetPin");
    boot0Pin.text = logic.getState("stm32prog.boot0Pin");
    boot1Pin.text = logic.getState("stm32prog.boot1Pin");
    bitrate.text = logic.getState("stm32prog.bitrate");
    rxPin.text = logic.getState("stm32prog.rxPin");
    txPin.text = logic.getState("stm32prog.txPin");
  }

  SColumn {
    style: "block fill";
    SRow {
      SLabel {
        attr.paddingHorizontal: 0;
        style: "text-h1 left";
        text: "STM32 Programmer"
      }
    }

    SRow {
      SLabel {
        span: 2;
        attr.paddingHorizontal: 0;
        text: "Firmware Update";
        style: "left";
      }

      SGroup {
        span: 2;
        style: "right";
        SButton {
          style: "btn-primary text-semi-bold";
          icon: Fa.Icon.download;
          text: "Program";
          onClicked: {
            //download the image to start programming
            var dest = "/home/" + imageFile.text.split('/').pop();
            logic.copyToDevice(imageFile.text, dest);
          }
        }

        SButton {
          span: 2;
          label: "Browse";
          icon: Fa.Icon.folder_open;
          style: "btn-outline-secondary right text-semi-bold";
          onClicked: imageDialog.visible = true;

          FileDialog {
            id: imageDialog;
            onAccepted: {
              imageFile.text = fileUrl;
            }
          }
        }

        SButton {
          span: 2;
          label: "Abort";
          icon: Fa.Icon.times;
          style: "btn-danger text-semi-bold";
          onClicked: {
            logic.killApp("stm32prog");
          }
        }

      }
    }

    SInput {
      id: imageFile;
      style: "btn-outline-secondary right";
      placeholder: "Binary Image File";
    }

    SHLine{}

    SRow {
      SLabel {
        style: "btn-primary left";
        text: "Actions";
        attr.paddingHorizontal: 0;
        span: 2;
      }

      SGroup {
        span: 2;
        style: "right";

        SButton {
          icon: Fa.Icon.terminal;
          style: "btn-primary text-semi-bold";
          onClicked: {
            logic.runApp("uartprobe -p 0");
          }

          SToolTip {
            text: "Listen to UART";
          }
        }

        SButton {
          icon: Fa.Icon.repeat;
          style: "btn-danger text-semi-bold";
          onClicked: {

          }
          SToolTip {
            text: "Reset Target";
          }
        }
      }
    }

    SHLine{}

    SRow {
      SLabel {
        style: "btn-primary left";
        text: "Options";
        attr.paddingHorizontal: 0;
        span: 2;
      }

      SGroup {
        span: 2;
        style: "right";

        SButton {
          id: showButton;
          icon: options.visible ? Fa.Icon.minus: Fa.Icon.plus;
          style: "btn-outline-secondary text-semi-bold";
          onClicked: {
            options.visible = !options.visible;
          }
        }
      }
    }

    SContainer {
      id: options;
      SRow {
        SLabel {
          span: 2;
          style: "left";
          text: "UART";
        }
        SInput {
          id: uartPort;
          span:2;
          style: "right text-center";
        }
        SLabel {
          span: 2;
          style: "left";
          text: "Bitrate";
        }
        SInput {
          id: bitrate;
          span:2;
          style: "right text-center";
        }
        SLabel {
          span: 2;
          style: "left";
          text: "RX";
        }
        SInput {
          id: rxPin;
          span:2;
          style: "right text-center";
          placeholder: "Default";
        }
        SLabel {
          span: 2;
          style: "left";
          text: "TX";
        }
        SInput {
          id: txPin;
          span:2;
          style: "right text-center";
          placeholder: "Default";
      }
        SLabel {
          span: 2;
          style: "left";
          text: "Reset";
        }
        SInput {
          id: resetPin;
          span:2;
          style: "right text-center";
        }
        SLabel {
          span: 2;
          style: "left";
          text: "Boot0";
        }
        SInput {
          id: boot0Pin;
          span:2;
          style: "right text-center";
        }
        SLabel {
          span: 2;
          style: "left";
          text: "Boot1";
        }
        SInput {
          id: boot1Pin;
          span:2;
          style: "right text-center";
          placeholder: "Ignore";
      }
      }
    }

    SHLine{}

    SRow {
      SLabel {
        span: 2;
        style: "left";
        text: "UART Terminal";
        attr.paddingHorizontal: 0;
      }

      SButton {
        span: 2;
        style: "btn-outline-secondary right text-semi-bold";
        text: "Clear";
        icon: Fa.Icon.times;
        onClicked: {
          terminalTextBox.textBox.clear();
        }
      }
    }

    SInput {
      id: executeInput;
      placeholder: "Send";
      Keys.onReturnPressed: {
        //write to the UART
      }
    }

    SProgressBar {
      visible: logic.progressMax != 0;
      value: logic.progressMax ? logic.progress / logic.progressMax : 0;
      style: "block success sm";
    }

    STextBox {
      id: terminalTextBox;
      style: "fill";
      implicitHeight: 50;
      attr.textFont: STheme.font_family_monospace.name;
      textBox.readOnly: true;
      textBox.text: "Hello World!";
      Connections {
        target: logic;
        onStdioChanged: {
          terminalTextBox.textBox.insert(terminalTextBox.textBox.length, value);
        }
      }
    }
  }
}
