import React, { useState } from "react";
import { ethers } from "ethers";

function AcceptLoan({ contract }) {
  const [refugeeAddress, setRefugeeAddress] = useState("");

  const handleAcceptLoan = async () => {
    try {
      const tx = await contract.approveLoan(refugeeAddress);
      await tx.wait();
      alert("Loan Approval Successful!");
    } catch (error) {
      alert("Loan Approval Failed: " + error.message);
    }
  };

  return (
    <div className="accept-loan-container">
      <h2>Accept Loan</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleAcceptLoan();
        }}
      >
        <label>
          Refugee Address:
          <input
            type="text"
            value={refugeeAddress}
            onChange={(e) => setRefugeeAddress(e.target.value)}
          />
        </label>
        <br />
        <br />
        <button type="submit">Accept Loan</button>
      </form>
    </div>
  );
}

export default AcceptLoan;
