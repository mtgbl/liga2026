const { readFile } = require('fs/promises');
const { parse } = require('csv-parse');
const { stringify } = require('csv-stringify/sync');
const process = require('process');

async function main() {
    const { event, source } = parseParams();

    // setup name replacer
    const nameReplacementsPath = './name_replacements.csv';
    const nameReplacements = await readCsv(nameReplacementsPath);
    const nameReplacer = replaceName(nameReplacements);

    // read
    const data = await readCsv(source);

    // transform
    const transfomer = transform(event, nameReplacer);
    const transformedData = data.map(transfomer);
    const csvOut = stringify(transformedData, stringifyOptions);

    // output csv to stdout
    process.stdout.write(csvOut);
}

function parseParams() {
    if(process.argv.length !== 3) {
        const execPath = process.argv[1];
        const scriptName = execPath.substring(execPath.lastIndexOf('/'+1));
        console.log(`Usage: ${scriptName} [path to csv]`);
        process.exit(-1);
    }
    const source = process.argv[2];
    const event = source.substring(source.lastIndexOf('/') + 1, source.lastIndexOf('.'));
    return {
        event,
        source,
    };
}

// see: https://csv.js.org/stringify/options/
const stringifyOptions = {
    columns: ['event', 'name', 'rank', 'points', 'wins', 'losses', 'draws', 'omw', 'gw', 'ogw'],
    delimiter: ',',
    header: false,
};

// see: https://csv.js.org/parse/options/
const parsersOptions = {
    encoding: 'utf8',
    delimiter: ',',
    columns: true,
    trim: true,
    skip_empty_lines: true,
};

async function readCsv(path, options = parsersOptions){
    return new Promise(async (resolve, reject) => {
        const encoding = options.encoding || defaultOptions.encoding;
        const csvData = await readFile(path, encoding);
        parse(csvData, options, (err, records) => {
            if (err) {
                reject(err);
            } else {
                resolve(records);
            }
        });
    });
}

function transform(event, nameReplacer) {
    return (entry) => {
        let wld = entry['W/L/D'].split('/');
        return {
            event,
            name: nameReplacer(entry.Name),
            rank: entry.Rank,
            points: entry.Points,
            wins: wld[0],
            losses: wld[1],
            draws: wld[2],
            omw: (Number.parseFloat(entry['OMW%']) / 100).toFixed(3),
            gw: (Number.parseFloat(entry['GW%']) / 100).toFixed(3),
            ogw: (Number.parseFloat(entry['OGW%']) / 100).toFixed(3),
        }
    }
}

function replaceName(nameReplacements) {
    const replacements = new Map();
    for (const nameReplacement of nameReplacements) {
        replacements.set(nameReplacement.name_from, nameReplacement.name_to);
    }
    return (nameToReplace) => {
        if (replacements.has(nameToReplace)) {
            return replacements.get(nameToReplace);
        } else {
            return nameToReplace;
        }
    }
}

if (require.main === module) {
    main()
        .catch((e) => {
            throw e
        }).finally(async () => {
    });
}
