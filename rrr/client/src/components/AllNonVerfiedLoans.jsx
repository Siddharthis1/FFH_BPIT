import React, { useState, useEffect } from "react";


function AllNonVerifiedLoans({ contract }) {
  const [nonVerifiedLoans, setNonVerifiedLoans] = useState([]);

  useEffect(() => {
    const fetchNonVerifiedLoans = async () => {
      try {
        const loans = await contract.getAllNonVerifiedLoans();
        setNonVerifiedLoans(loans);
      } catch (error) {
        console.error("Error fetching non-verified loans:", error);
      }
    };

    fetchNonVerifiedLoans();
  }, [contract]);

  return (
    <div className="all-non-verified-loans-container">
      <h2>All Non-Verified Loans</h2>
      {nonVerifiedLoans.length > 0 ? (
        <table className="loans-table">
          <thead>
            <tr>
              <th>Refugee Address</th>
              <th>Loan Amount</th>
              <th>Repayment Scheme</th>
            </tr>
          </thead>
          <tbody>
            {nonVerifiedLoans.map((loan, index) => (
              <tr key={index}>
                <td>{loan.refugeeAddress}</td>
                <td>{ethers.utils.formatEther(loan.loanAmount)} ETH</td>
                <td>{loan.repaymentScheme}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <p className="no-data">No non-verified loans found.</p>
      )}
    </div>
  );
}

export default AllNonVerifiedLoans;
