<?php
$title = "My Nested HTML Example";
$date = date('Y-m-d H:i:s');
$items = ['Apple', 'Banana', 'Cherry', 'Date', 'Fig', 'Grape', 'Honeydew'];

function generateList($items) {
    $output = '<ul>';
    foreach ($items as $item) {
        $output .= "<li>$item</li>";
    }
    $output .= '</ul>';
    return $output;
}

$greeting = "Welcome to my PHP nested HTML example!";
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $title; ?></title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f4;
            margin: 0;
            padding: 20px;
        }
        header {
            background: #35424a;
            color: #ffffff;
            padding: 10px 0;
            text-align: center;
        }
        main {
            margin: 20px 0;
            padding: 20px;
            background: #ffffff;
            border-radius: 5px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        footer {
            text-align: center;
            margin-top: 20px;
            padding: 10px 0;
            background: #35424a;
            color: #ffffff;
        }
        .item-list {
            margin-top: 20px;
        }
    </style>
</head>
<body>

<header>
    <h1><?php echo $title; ?></h1>
    <p><?php echo $greeting; ?></p>
    <p>Current Date and Time: <?php echo $date; ?></p>
</header>

<main>
    <section>
        <h2>Item List</h2>
        <div class="item-list">
            <?php echo generateList($items); ?>
        </div>
    </section>

    <section>
        <h2>More Information</h2>
        <p>This section can hold additional information about the items listed above.</p>
        <div>
            <h3>Item Details</h3>
            <ul>
                <li>
                    <strong>Apple:</strong> A sweet red fruit.
                </li>
                <li>
                    <strong>Banana:</strong> A long yellow fruit.
                </li>
                <li>
                    <strong>Cherry:</strong> A small round stone fruit.
                </li>
                <li>
                    <strong>Date:</strong> A sweet fruit from the date palm.
                </li>
                <li>
                    <strong>Fig:</strong> A sweet fruit with a unique texture.
                </li>
                <li>
                    <strong>Grape:</strong> A small fruit that comes in bunches.
                </li>
                <li>
                    <strong>Honeydew:</strong> A sweet summer melon.
                </li>
            </ul>
        </div>
    </section>

    <section>
        <h2>Feedback</h2>
        <form method="POST" action="submit_feedback.php">
            <label for="name">Your Name:</label><br>
            <input type="text" id="name" name="name" required><br><br>
            <label for="feedback">Your Feedback:</label><br>
            <textarea id="feedback" name="feedback" rows="4" required></textarea><br><br>
            <input type="submit" value="Submit Feedback">
        </form>
    </section>
</main>

<footer>
    <p>&copy; <?php echo date('Y'); ?> My Website. All Rights Reserved.</p>
</footer>

</body>
</html>

