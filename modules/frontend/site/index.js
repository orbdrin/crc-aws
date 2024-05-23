async function update_count() {
    try {
        let response = await fetch("https://25o09dvlk9.execute-api.us-east-1.amazonaws.com/crc-http-lambda-stage/crc-visitors-count", {
            method: 'GET'
        });
        
        let data = await response.json();
        document.getElementById("count").innerHTML = data['count'];
        console.log(data);
        return data;
    } catch(err) {
        console.error(err);
	}
}

update_count();