const greeting = require('random-greetings');

function prepare_message(name: string) {
    const msg = `${greeting.greet()} ${name}`;
    return msg;
}

function greet_normal(name: string) {
    const msg = prepare_message(name);
    return msg;
}

function greet_promise(name: string) {
    return new Promise((resolve, reject) => {
        const msg = prepare_message(name);
        setTimeout(() => {
            resolve(msg);
        }, 3000);
    });
}

function timeout(ms: number) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

async function greet_async(name: string) {
    await timeout(3000);
    const msg = prepare_message(name);
    return msg;
}

export { greet_normal, greet_promise, greet_async };
