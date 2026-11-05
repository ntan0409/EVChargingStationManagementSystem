import { useState } from "react";
import { Eye, EyeOff, Mail, Lock } from "lucide-react";

const InputField = ({ type, placeholder, icon, name, value, onChange }) => {
  const [isPasswordShown, setIsPasswordShow] = useState(false);

  // Map icon names to lucide-react components
  const getIcon = () => {
    switch (icon) {
      case 'mail':
        return <Mail size={20} />;
      case 'lock':
        return <Lock size={20} />;
      default:
        return <i className="material-symbols-rounded">{icon}</i>;
    }
  };

  return (
    <div className="input-wrapper">
      <input
        name={name}
        value={value}
        onChange={onChange}
        type={isPasswordShown ? 'text' : type}
        placeholder={placeholder}
        className="input-field"
        required
      />
      <span className="input-icon">
        {getIcon()}
      </span>
      {type === 'password' && (
        <button
          type="button"
          onClick={() => setIsPasswordShow(prevState => !prevState)}
          className="eye-icon-button"
          aria-label={isPasswordShown ? 'Ẩn mật khẩu' : 'Hiện mật khẩu'}
        >
          {isPasswordShown ? <Eye size={20} /> : <EyeOff size={20} />}
        </button>
      )}
    </div>
  );
};

export default InputField;
