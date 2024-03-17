import React, { useState } from "react";
import { ethers } from "ethers";

function RemindForPayment({ contract }) {
  const [message, setMessage] = useState("");

  const handleSendReminder = async () => {
    try {
      const tx = await contract.remindForRepayment();
      await tx.wait();
      alert("Reminder Sent Successfully!");
    } catch (error) {
      alert("Reminder Sending Failed: " + error.message);
    }
  };

  return (
    <div className="remind-for-payment-container">
      <h2>Send Reminder for Payment</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleSendReminder();
        }}
      >
        <label>
          Message:
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            rows={4}
            cols={50}
          />
        </label>
        <br />
        <br />
        <button type="submit">Send Reminder</button>
      </form>
    </div>
  );
}

export default RemindForPayment;
