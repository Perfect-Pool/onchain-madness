/**
 * Script to convert a UTC ISO date to Brasilia time
 * Usage: yarn convert-date "2025-03-20T01:10:00+00:00"
 */

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  underscore: '\x1b[4m',
  blink: '\x1b[5m',
  reverse: '\x1b[7m',
  hidden: '\x1b[8m',
  
  // Foreground (text) colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  
  // Background colors
  bgBlack: '\x1b[40m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
  bgWhite: '\x1b[47m'
};

// Helper function to colorize text
const colorize = (text, color) => {
  return `${color}${text}${colors.reset}`;
};

// Get the date argument from command line
const dateArg = process.argv[2];

if (!dateArg) {
  console.error(colorize('Error: Please provide a UTC ISO date as an argument', colors.red + colors.bright));
  console.error(colorize('Example:', colors.yellow) + colorize(' yarn convert-date "2025-03-20T01:10:00+00:00"', colors.green));
  process.exit(1);
}

try {
  // Parse the input date
  const utcDate = new Date(dateArg);
  
  // Check if the date is valid
  if (isNaN(utcDate.getTime())) {
    throw new Error('Invalid date format');
  }
  
  // Convert to Brasilia time (UTC-3)
  // Create a formatter that explicitly uses Brasilia timezone
  const formatter = new Intl.DateTimeFormat('en-US', {
    timeZone: 'America/Sao_Paulo',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
    timeZoneName: 'short'
  });
  
  const brasiliaTime = formatter.format(utcDate);
  
  // Also show the raw date object conversion
  const offsetHours = -3;
  const rawBrasiliaDate = new Date(utcDate.getTime() + offsetHours * 60 * 60 * 1000);
  const brasiliaIsoTime = rawBrasiliaDate.toISOString().replace('Z', '-03:00');
  
  // Print a decorative header
  console.log('\n' + colorize('╔══════════════════════════════════════════════════════════╗', colors.cyan));
  console.log(colorize('║', colors.cyan) + colorize('                CONVERSOR DE FUSO HORÁRIO                 ', colors.yellow + colors.bright) + colorize('║', colors.cyan));
  console.log(colorize('╚══════════════════════════════════════════════════════════╝', colors.cyan));
  
  // Output both times for comparison with colors
  console.log('\n' + colorize('► Input UTC time:', colors.blue + colors.bright) + ' ' + colorize(dateArg, colors.white));
  
  console.log('\n' + colorize('► Brasilia time (formatted):', colors.green + colors.bright) + ' ' + colorize(brasiliaTime, colors.white));
  
} catch (error) {
  console.error(colorize('Error: ' + error.message, colors.red + colors.bright));
  console.error(colorize('Please provide a valid ISO date format', colors.yellow));
  console.error(colorize('Example:', colors.yellow) + colorize(' yarn convert-date "2025-03-20T01:10:00+00:00"', colors.green));
  process.exit(1);
}