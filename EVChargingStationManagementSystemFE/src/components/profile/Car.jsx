  import React, { useState, useEffect } from "react";
  import "./Car.css";
  import { getVehicleModels, addVehicalModel, deleteVehicle, updateVehicle } from "../../API/Admin";
  import { ToastContainer, toast } from "react-toastify";
  import "react-toastify/dist/ReactToastify.css";

  const MyVehicles = () => {
    const [vehicles, setVehicles] = useState([]);
    const [selectedVehicle, setSelectedVehicle] = useState(null);
    const [loading, setLoading] = useState(true);
    const [showPopup, setShowPopup] = useState(false);
    const [vehicleEdit, setVehicleEdit] = useState({
      id: "",
      batteryCapacityKWh: 0,
      recommendedChargingPowerKW: 0,
    });

    const [newVehicle, setNewVehicle] = useState({
      modelName: "",
      modelYear: "",
      vehicleType: "",
      batteryCapacityKWh: 0,
      recommendedChargingPowerKW: 0,
      imageUrl: "",
    });

    const role = localStorage.getItem("role") || "admin";

    // API lấy danh sách xe
    const fetchVehicles = async () => {
      setLoading(true);
      try {
        const res = await getVehicleModels();
        const dataArray = res.data || [];
        setVehicles(dataArray);
        localStorage.setItem("vehicleList", JSON.stringify(dataArray));
        if (dataArray.length > 0) setSelectedVehicle(dataArray[0].id);
        else setSelectedVehicle(null);
      } catch (err) {
        console.error("Lỗi khi lấy danh sách xe:", err);
      } finally {
        setLoading(false);
      }
    };

    useEffect(() => {
      fetchVehicles();
    }, []);

    const handleChange = (e) => {
      const id = e.target.value;
      setSelectedVehicle(id);
      const selected = vehicles.find((v) => v.id === (id));
      if (selected)
        setVehicleEdit({
          id: selected.id,
          batteryCapacityKWh: selected.batteryCapacityKWh,
          recommendedChargingPowerKW: selected.recommendedChargingPowerKW,
        });
    };

    // API thêm xe
    const handleAddVehicle = async (e) => {
      e.preventDefault();
      try {
        await addVehicalModel(
          newVehicle.modelName,
          newVehicle.modelYear,
          newVehicle.vehicleType,
          newVehicle.batteryCapacityKWh,
          newVehicle.recommendedChargingPowerKW,
          newVehicle.imageUrl
        );
        await fetchVehicles();
        setShowPopup(false);
        setNewVehicle({
          modelName: "",
          modelYear: "",
          vehicleType: "",
          batteryCapacityKWh: 0,
          recommendedChargingPowerKW: 0,
          imageUrl: "",
        });
        toast.success("✅ Đã thêm xe mới thành công!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      } catch (err) {
        console.error("Lỗi khi thêm xe:", err);
        toast.error("❌ Thêm xe thất bại!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      }
    };

    // Xóa xe
    const handleDeleteVehicle = async (id) => {
      if (!id) return;
      if (!window.confirm("Bạn có chắc muốn xóa xe này?")) return;

      try {
        // Gọi API xóa trực tiếp database
        await deleteVehicle(id); // backend phải xử lý xóa trong DB
        // Load lại danh sách từ DB
        const res = await getVehicleModels();
        setVehicles(res.data || []);
        toast.success("Đã xóa xe thành công!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      } catch (error) {
        console.error("Lỗi xóa xe:", error);
        toast.error("Xóa xe thất bại!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      }
    };

    // Cập nhật Overdrive update api 
    const handleUpdateVehicle = async () => {
      try {
        const updatedData = {
          id: vehicleEdit.id,
          batteryCapacityKWh: vehicleEdit.batteryCapacityKWh,
          recommendedChargingPowerKW: vehicleEdit.recommendedChargingPowerKW,
        };
        await updateVehicle(updatedData);
        await fetchVehicles();
        toast.success("⚙️ Overdrive lưu thành công!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      } catch (error) {
        console.error("Lỗi khi cập nhật xe:", error);
        toast.error("Cập nhật thất bại!", {
          position: "top-right",
          autoClose: 2000,
          theme: "colored",
        });
      }
    };

    if (loading) return <p>Đang tải xe của bạn...</p>;

    const currentVehicle = vehicles.find((v) => v.id === parseInt(selectedVehicle));

    return (
      <div className="my-vehicles-container">
        <h2>Xe của tôi</h2>

        <div className="vehicle-card">
          {currentVehicle && (
              <img
                src={currentVehicle.imageUrl }
                alt={currentVehicle.modelName || currentVehicle.modelName || "Xe điện"}
                style={{ width: "200px", height: "auto" }}
                
              />
            )}

          <div className="vehicle-info">
            <label htmlFor="vehicle-select">Chọn xe:</label>
            <select id="vehicle-select" value={selectedVehicle || ""} onChange={handleChange}>
              {vehicles.map((v) => (
                <option key={v.id} value={v.id}>
                  {v.modelName || v.modelName || v.name}
                </option>
              ))}
            </select>

            {/* Nút Xác nhận */}
            <button
              className="confirm-btn"
              onClick={() => {
                const chosen = vehicles.find((v) => v.id === selectedVehicle);
                if (chosen) {
                  localStorage.setItem("selectedVehicleId", chosen.id);
                  toast.success(`Đã lưu lựa chọn: ${chosen.modelName || chosen.modelName}`, {
                    position: "top-right",
                    autoClose: 2000,
                    theme: "colored",
                  });
                } else {
                  toast.warning(" Vui lòng chọn xe!", {
                    position: "top-right",
                    autoClose: 2000,
                    theme: "colored",
                  });
                }
              }}
            >
              Xác nhận
            </button>
          </div>

          {currentVehicle && (
            <div className="vehicle-overdrive">
              <h4>⚙️ Overdrive thông số</h4>
              <div className="form-group">
                <label>Dung lượng pin (kWh):</label>
                <input
                  type="number"
                  value={vehicleEdit.batteryCapacityKWh}
                  onChange={(e) =>
                    setVehicleEdit({ ...vehicleEdit, batteryCapacityKWh: parseFloat(e.target.value) })
                  }
                />
              </div>
              <div className="form-group">
                <label>Công suất sạc đề xuất (kW):</label>
                <input
                  type="number"
                  value={vehicleEdit.recommendedChargingPowerKW}
                  onChange={(e) =>
                    setVehicleEdit({ ...vehicleEdit, recommendedChargingPowerKW: parseFloat(e.target.value) })
                  }
                />
              </div>

              <div className="vehicle-overdrive-actions">
                <button onClick={handleUpdateVehicle} className="save-btn">
                  Lưu Overdrive
                </button>
              </div>
            </div>
          )}

          <div className="vehicle-buttons">
            <button type="button" className="add-vehicle-btn" onClick={() => setShowPopup(true)}>
              Thêm xe
            </button>

            {selectedVehicle && (
              <button type="button" className="delete-vehicle-btn" onClick={() => handleDeleteVehicle(selectedVehicle)}>
                Xóa xe
              </button>
            )}
          </div>
        </div>

        {/* Popup thêm xe */}
        {showPopup && (
          <div className="vehicle-popup-overlay">
            <div className="vehicle-popup">
              <h3>Thêm xe mới</h3>
              <form onSubmit={handleAddVehicle} className="vehicle-form">
                <div className="form-group">
                  <label>Tên xe:</label>
                  <input
                    type="text"
                    value={newVehicle.modelName}
                    onChange={(e) => setNewVehicle({ ...newVehicle, modelName: e.target.value })}
                    required
                  />
                </div>

                {role === "admin" && (
                  <>
                    <div className="form-group">
                      <label>Năm sản xuất:</label>
                      <input
                        type="number"
                        value={newVehicle.modelYear}
                        onChange={(e) =>
                          setNewVehicle({ ...newVehicle, modelYear: parseInt(e.target.value) })
                        }
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Dung lượng pin (kWh):</label>
                      <input
                        type="number"
                        value={newVehicle.batteryCapacityKWh}
                        onChange={(e) =>
                          setNewVehicle({
                            ...newVehicle,
                            batteryCapacityKWh: parseFloat(e.target.value),
                          })
                        }
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>Công suất sạc đề xuất (kW):</label>
                      <input
                        type="number"
                        value={newVehicle.recommendedChargingPowerKW}
                        onChange={(e) =>
                          setNewVehicle({
                            ...newVehicle,
                            recommendedChargingPowerKW: parseFloat(e.target.value),
                          })
                        }
                        required
                      />
                    </div>
                    <div className="form-group">
                      <label>URL hình ảnh:</label>
                      <input
                        type="text"
                        value={newVehicle.imageUrl}
                        onChange={(e) => setNewVehicle({ ...newVehicle, imageUrl: e.target.value })}
                        required
                      />
                    </div>
                  </>
                )}

                <div className="form-group">
                  <label>Loại xe:</label>
                  <select
                    value={newVehicle.vehicleType}
                    onChange={(e) => setNewVehicle({ ...newVehicle, vehicleType: Number(e.target.value) })}
                    required
                  >
                    <option value="">Chọn loại xe</option>
                    <option value={0}>Xe Máy</option>
                    <option value={1}>Xe Hơi</option>
                    <option value={2}>Không xác định</option>
                  </select>
                </div>

                <div className="vehicle-popup-actions">
                  <button type="submit" className="save-btn">
                    Lưu
                  </button>
                  <button type="button" className="cancel-btn" onClick={() => setShowPopup(false)}>
                    Hủy
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Toast container */}
        <ToastContainer />
      </div>
    );
  };

  export default MyVehicles;
