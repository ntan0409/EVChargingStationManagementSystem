import React, { useState } from "react";
import Lottie from "react-lottie-player";
import carAnimation from "../animation/Car animation.json";
import plugAnimation from "../animation/plug-in.json";
import chargingAnimation from "../animation/charging.json";
import "./IOTChargingSystem.css";

// Countdown Popup
const CountdownPopup = ({ countdown, onComplete }) => {
  const [sec, setSec] = React.useState(countdown);

  React.useEffect(() => {
    setSec(countdown);
    if (countdown <= 0) return;

    const interval = setInterval(() => {
      setSec((prev) => {
        if (prev <= 1) {
          clearInterval(interval);
          onComplete?.();
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(interval);
  }, [countdown, onComplete]);

  if (sec <= 0) return null;

  return (
    <div className="countdown-popup">
      ⏳ {sec}
    </div>
  );
};

const IOTChargingSystem = () => {
  const [stage, setStage] = useState("intro");
  const [state, setState] = useState("idle");
  const [countdown, setCountdown] = useState(0);

  const handlePlugIn = () => {
    if (state !== "idle") return;
    setCountdown(0);
    setState("plugging");
  };

  const handleUnplug = () => {
    if (state !== "charging") return;
    setState("unplugging");
    setTimeout(() => setState("idle"), 2000);
  };

  return (
    <div className="iot-container">
      {/* INTRO SCREEN */}
      {stage === "intro" && (
        <div className="iot-intro">
          <Lottie animationData={carAnimation} play loop={false} style={{ width: "80%", height: "60vh" }} />
          <button className="start-btn" onClick={() => setStage("chargingUI")}>
            🚗 Tiến vào khu vực sạc
          </button>
        </div>
      )}

      {/* CHARGING UI */}
      {stage === "chargingUI" && (
        <div className="iot-station-box zoom-in-down">
          <h2 className="iot-title">🔌 Trạm Sạc IOT</h2>

          <div className="iot-animation">
            {/* Idle */}
            {state === "idle" && (
              <Lottie animationData={plugAnimation} play={false} style={{ width: "100%", height: "100%" }} />
            )}

            {/* Plugging */}
            {state === "plugging" && (
              <div style={{ position: "relative", width: "100%", height: "100%" }}>
                <Lottie
                  animationData={plugAnimation}
                  play
                  loop={false}
                  segments={[0, 81]}
                  style={{ width: "100%", height: "100%" }}
                  onComplete={() => setCountdown(3)}
                />
                {countdown > 0 && (
                  <CountdownPopup countdown={countdown} onComplete={() => setState("charging")} />
                )}
              </div>
            )}

            {/* Charging */}
            {state === "charging" && (
              <Lottie animationData={chargingAnimation} play loop segments={[34, 104]} style={{ width: "100%", height: "100%" }} />
            )}

            {/* Unplugging */}
            {state === "unplugging" && (
              <Lottie animationData={plugAnimation} play loop={false} segments={[82, 0]} style={{ width: "100%", height: "100%" }} />
            )}
          </div>

          <p className="iot-status">
            {state === "idle"
              ? "🪫 Chưa cắm sạc"
              : state === "plugging"
              ? "🔌 Đang cắm sạc..."
              : state === "charging"
              ? "⚡ Đang sạc..."
              : "🔋 Đang rút sạc..."}
          </p>

          <div className="iot-buttons">
            <button onClick={handlePlugIn} disabled={state !== "idle"}>Cắm sạc</button>
            <button onClick={handleUnplug} disabled={state !== "charging"}>Rút sạc</button>
            <button onClick={() => setStage("intro")}>↩ Quay lại</button>
          </div>
        </div>
      )}
    </div>
  );
};

export default IOTChargingSystem;
