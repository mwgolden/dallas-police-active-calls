function formatDate(DateString) {
    const date = new Date(DateString)
    const formattedDate = date.toLocaleDateString('en-US', 
        {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        }
    )
    return formattedDate
}

function toTitleCase(str) {
    return str
        .split(' ')
        .map(word => word.charAt(0).toUpperCase + word.slice(1))
        .join(' ')
}

export { formatDate, toTitleCase }