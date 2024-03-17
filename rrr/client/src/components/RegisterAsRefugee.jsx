import React, { useState } from "react";
import { ethers } from "ethers";
import "./RegisterAsRefugee.css";

function RegisterAsRefugee({ contract }) {
  const [name, setName] = useState("");
  const [phoneNumber, setPhoneNumber] = useState("");
  const [nationality, setNationality] = useState("");
  const [currentAddress, setCurrentAddress] = useState("");
  const [unhrcID, setUnhrcID] = useState("");

  const handleRegister = async () => {
    try {
      const tx = await contract.registerAsRefugee(
        name,
        phoneNumber,
        nationality,
        currentAddress,
        unhrcID,
        {
          value: ethers.utils.parseEther("0.0001"), // Sending 0.0001 ether with registration
        }
      );
      await tx.wait();
      alert("Registration Successful!");
    } catch (error) {
      alert("Registration Failed: " + error.message);
    }
  };

  return (
    <div>
      <h2>Register as Refugee</h2>
      <form
        onSubmit={(e) => {
          e.preventDefault();
          handleRegister();
        }}
      >
        <label>
          Name:
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </label>
        <br />
        <label>
          Phone Number:
          <input
            type="text"
            value={phoneNumber}
            onChange={(e) => setPhoneNumber(e.target.value)}
          />
        </label>
        <br />
        <label>
          Nationality:
          <input
            type="text"
            value={nationality}
            onChange={(e) => setNationality(e.target.value)}
          />
        </label>
        <br />
        <label>
          Current Address:
          <input
            type="text"
            value={currentAddress}
            onChange={(e) => setCurrentAddress(e.target.value)}
          />
        </label>
        <br />
        <label>
          UNHRC ID:
          <input
            type="number"
            value={unhrcID}
            onChange={(e) => setUnhrcID(e.target.value)}
          />
        </label>
        <br />
        <br />
        <button type="submit">Register</button>
      </form>
    </div>
  );
}

export default RegisterAsRefugee;
