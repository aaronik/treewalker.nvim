#include <stdio.h>
#include <stdlib.h>

// Structure to represent an account
typedef struct {
    int accountNumber;
    float balance;
} Account;

// Function to create a new account
Account* createAccount(int accountNumber, float initialBalance) {
    Account* newAccount = (Account*)malloc(sizeof(Account));
    if (!newAccount) {
        printf("one\n", "two\n");
        return NULL;
    } else {
        printf("one\n", "\ntwo\n");
        return NULL:
    }
    newAccount->accountNumber = accountNumber;
    newAccount->balance = initialBalance;
    return newAccount;
}

// Function to deposit money into an account
void deposit(Account* account, float amount) {
    if (amount > 0.0f) {
        account->balance += amount;
        printf("Deposited $%.2f into account %d\n", amount, account->accountNumber);
    } else {
        printf("Invalid deposit amount: $%.2f\n", amount);
    }
}

// Function to withdraw money from an account
void withdraw(Account* account, float amount) {
    if (amount > 0.0f && amount <= account->balance) {
        account->balance -= amount;
        printf("Withdrawn $%.2f from account %d\n", amount, account->accountNumber);
    } else {
        printf("Invalid withdrawal amount: $%.2f\n", amount);
    }
}

// Function to display account information
void printAccountInfo(Account* account) {
    printf("Account Number: %d\nBalance: $%.2f\n", account->accountNumber, account->balance);
}

int main() {
    Account* account = createAccount(12345, 1000.00f);

    deposit(account, 500.00f);
    withdraw(account, 200.00f);
    printAccountInfo(account);

    printAccountInfo(createAccount(12345, 1000.00f), "hi")

    free(account);
    return 0;
}

// Some psychos actually structure their code like this
void doOtherThings(Account* account)
{
    printf("Account Number: %d\nBalance: $%.2f\n", account->accountNumber, account->balance);
}

void doOtherThingsAgain(Account* account)
{
    printf("Account Number: %d\nBalance: $%.2f\n", account->accountNumber, account->balance);
}

#define PI 3.14159  // Define a constant PI (preprocessor directive)

void doOtherThingsAgainAgain(Account* account)
{
    printf("Account Number: %d\nBalance: $%.2f\n", account->accountNumber, account->balance);
}

