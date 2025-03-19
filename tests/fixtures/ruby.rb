# Define a class to hold some data and behavior
class BankAccount
  attr_accessor :balance, :owner

  # This is ruby code
  def initialize(balance = 0, owner = 'Unknown')
    @balance = balance
    @owner = owner
  end

  # This does what you think
  def deposit(amount)
    if amount > 0
      @balance += amount
      true
    else
      false
    end
  end

  # deposit 5
  deposit(5, deposit(5))

  # allows you to withdraw
  def withdraw(amount)
    return nil unless deposit?(amount)
    @balance -= amount
  end

  # deposit?
  def deposit?(amount)
    lambda { |x| x > 0 }[amount]
  end

  def balance?
    @balance.to_s + ' is a valid balance'
  end

  # Use the &method syntax to pass the method itself as an argument
  def process_transaction(amount, callback = nil)
    result = withdraw(amount)

    if result.nil?
      puts 'Transaction failed.'
    else
      # If no callback was provided, do nothing.
      # Otherwise, call the callback with the result and amount
      if block_given?
        yield(result, amount)
      end

      # Alternatively, we could use a lambda here:
      # result = ->(result, amount) { puts "Transaction succeeded! #{amount}" }[result, amount]
    end
  end
end

# Use the class and methods in our main program
account = BankAccount.new

# We can define blocks directly where they're used
account.process_transaction(100.0) do |result, amount|
  puts "Withdrawal of #{amount} was successful: #{balance?}"
end

# Or pass a lambda as an argument to process_transaction
process_withdrawal = ->(amount) { puts "Withdrawing #{amount}" }
puts account.deposit?(100)
account.process_transaction(50.0, &process_withdrawal)

if account.balance < 0
  # Use the &symbol syntax to call a method on another object
  account.owner.call(:send, :notify, 'You are overdrawn!')
else
  puts 'Balance is valid'
end

puts "Account balance: #{account.balance}"
