
use Library;
-- Books (BookID, Title, Author, PublicationYear, Status)
-- Members (MemberID, MemberName, Address, ContactNumber)
-- Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
CREATE TABLE Books (
  BookID INT PRIMARY KEY,
  Title VARCHAR(255),
  Author VARCHAR(255),
  PublicationYear INT,
  Status VARCHAR(10)
);

CREATE TABLE Members (
  MemberID INT PRIMARY KEY,
  Name VARCHAR(255),
  Address VARCHAR(255),
  ContactNumber VARCHAR(10)
);


CREATE TABLE Loans (
  LoanID INT PRIMARY KEY,
  BookID INT,
  MemberID INT,
  LoanDate DATE,
  ReturnDate DATE,
  FOREIGN KEY (BookId) REFERENCES Books (BookID),
  FOREIGN KEY (MemberID) REFERENCES Members (MemberID)
);


-- Insert values into the Books table
INSERT INTO Books (BookID, Title, Author, PublicationYear, Status)
VALUES
  (1, 'Book 1', 'Author 1', 2020, 'Available'),
  (2, 'Book 2', 'Author 2', 2018, 'Available'),
  (3, 'Book 3', 'Author 3', 2021, 'Available'),
  (4, 'Book 4', 'Author 4', 2019, 'Available'),
  (5, 'Book 5', 'Author 5', 2022, 'Available');

-- Insert values into the Members table
INSERT INTO Members (MemberID, Name, Address, ContactNumber)
VALUES
  (1, 'John Doe', '123 Main St', '555-1234'),
  (2, 'Jane Smith', '456 Elm St', '555-5678'),
  (3, 'Michael Johnson', '789 Oak St', '555-9012'),
  (4, 'Emily Brown', '321 Pine St', '555-3456'),
  (5, 'Daniel Wilson', '654 Maple St', '555-7890');

-- Insert values into the Loans table
INSERT INTO Loans (LoanID, BookID, MemberID, LoanDate, ReturnDate)
VALUES
  (1, 1, 1, '2023-06-01', '2023-06-15'),
  (2, 2, 2, '2023-06-02', '2023-06-16'),
  (3, 3, 3, '2023-06-03', '2023-06-17'),
  (4, 4, 4, '2023-06-04', '2023-06-18'),
  (5, 5, 5, '2023-06-05', '2023-06-19');

  --Delete members who have returned the book
  DELETE FROM Loans
  WHERE LoanID IN (1,2,3,4,5)

  --creating trigger to update the status column
IF EXISTS (SELECT * FROM sys.triggers WHERE name = 'update_book_status')
BEGIN
  DROP TRIGGER update_book_status
END
GO

CREATE TRIGGER update_book_status
ON Loans
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
  DECLARE @book_status VARCHAR(10)
  
  -- Update the Status column for loaned books
  UPDATE Books
  SET Status = 'Loaned'
  FROM Books
  INNER JOIN inserted ON Books.BookID = inserted.BookID

  -- Update the Status column for returned books
  UPDATE Books
  SET Status = 'Available'
  FROM Books
  INNER JOIN deleted ON Books.BookID = deleted.BookID
END
GO

SELECT * FROM Books;
SELECT * FROM Members;
SELECT * FROM Loans;
--CTE to return members who have borrowed 3 books
WITH BorrowCounts AS (
  SELECT MemberID, COUNT(*) AS NumOfBorrows
  FROM Loans
  GROUP BY MemberID
  HAVING COUNT(*) >= 3
)
SELECT M.Name
FROM Members M
INNER JOIN BorrowCounts B ON M.MemberID = B.MemberID;

--a vieew that displays details of all overdue loans,including book title,member name and no of over due days
CREATE VIEW OverdueLoansView AS
SELECT B.Title AS BookTitle, M.Name AS MemberName, DATEDIFF(DAY, L.LoanDate, GETDATE()) AS OverdueDays
FROM Loans L
JOIN Books B ON L.BookID = B.BookID
JOIN Members M ON L.MemberID = M.MemberID
WHERE DATEDIFF(DAY, L.LoanDate, GETDATE()) > 30;


--trigger to prevent borrowing more than 3 books
CREATE TRIGGER PreventExcessiveBorrowing
ON Loans
FOR INSERT
AS
BEGIN
    DECLARE @MemberID INT;
    DECLARE @TotalLoans INT;

    SELECT @MemberID = MemberID
    FROM inserted;

    SELECT @TotalLoans = COUNT(*)
    FROM Loans
    WHERE MemberID = @MemberID;

    IF @TotalLoans >= 3
    BEGIN
        RAISERROR('Cannot borrow more than three books at a time.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;




