<?php

// Script to extract text content from PDF files
require_once __DIR__ . '/vendor/autoload.php';

use Smalot\PdfParser\Parser;

function extractPdfContent($pdfPath) {
    try {
        $parser = new Parser();
        $pdf = $parser->parseFile($pdfPath);
        $text = $pdf->getText();
        return $text;
    } catch (Exception $e) {
        return "Error reading PDF: " . $e->getMessage();
    }
}

$pdfFiles = [
    'e66666.pdf' => 'C:\xampp3\htdocs\TerrenaLaravel\docs\Otros\e66666.pdf',
    'e72023.pdf' => 'C:\xampp3\htdocs\TerrenaLaravel\docs\Otros\e72023.pdf',
    'myinventory Feature Reference Manual v7.1.pdf' => 'C:\xampp3\htdocs\TerrenaLaravel\docs\Otros\myinventory Feature Reference Manual v7.1.pdf',
    'myinventory Standard Reports.pdf' => 'C:\xampp3\htdocs\TerrenaLaravel\docs\Otros\myinventory Standard Reports.pdf'
];

$results = [];

foreach ($pdfFiles as $name => $path) {
    echo "Extracting content from: $name\n";
    $content = extractPdfContent($path);
    $results[$name] = $content;
    echo "Extracted " . strlen($content) . " characters\n\n";
}

// Output results in a structured format
foreach ($results as $name => $content) {
    echo "=== CONTENT FROM: $name ===\n";
    echo $content . "\n";
    echo "=== END OF: $name ===\n\n";
}