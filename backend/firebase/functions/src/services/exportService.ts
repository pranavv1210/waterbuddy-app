export class ExportService {
  /**
   * Converts a list of objects into a standard CSV string.
   */
  static convertToCSV(data: Record<string, any>[]): string {
    if (!data || data.length === 0) {
      return '';
    }

    // Extract headers (keys from first object)
    const headers = Object.keys(data[0]);
    const csvRows: string[] = [];

    // Header row
    csvRows.push(headers.join(','));

    // Data rows
    for (const row of data) {
      const values = headers.map((header) => {
        const value = row[header];
        // Handle null, undefined, object structures, and escape double quotes
        if (value === null || value === undefined) {
          return '';
        }
        
        if (typeof value === 'object') {
          return `"${JSON.stringify(value).replace(/"/g, '""')}"`;
        }

        const stringValue = String(value);
        if (stringValue.includes(',') || stringValue.includes('"') || stringValue.includes('\n')) {
          return `"${stringValue.replace(/"/g, '""')}"`;
        }
        
        return stringValue;
      });
      csvRows.push(values.join(','));
    }

    return csvRows.join('\n');
  }
}
