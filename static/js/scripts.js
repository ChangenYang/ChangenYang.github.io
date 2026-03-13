

const content_dir = 'contents/'
const config_file = 'config.yml'
const section_names = ['home', 'publications', 'project', 'awards']


window.addEventListener('DOMContentLoaded', event => {
    const printButtons = document.querySelectorAll('#print-page-button, #print-page-button-mobile');

    // Activate Bootstrap scrollspy on the main nav element
    const mainNav = document.body.querySelector('#mainNav');
    if (mainNav) {
        new bootstrap.ScrollSpy(document.body, {
            target: '#mainNav',
            offset: 74,
        });
    };

    // Collapse responsive navbar when toggler is visible
    const navbarToggler = document.body.querySelector('.navbar-toggler');
    const responsiveNavItems = [].slice.call(
        document.querySelectorAll('#navbarResponsive .nav-link')
    );
    responsiveNavItems.map(function (responsiveNavItem) {
        responsiveNavItem.addEventListener('click', () => {
            if (window.getComputedStyle(navbarToggler).display !== 'none') {
                navbarToggler.click();
            }
        });
    });


    // Yaml
    const configReady = fetch(content_dir + config_file)
        .then(response => response.text())
        .then(text => {
            const yml = jsyaml.load(text);
            Object.keys(yml).forEach(key => {
                try {
                    document.getElementById(key).innerHTML = yml[key];
                } catch {
                    console.log("Unknown id and value: " + key + "," + yml[key].toString())
                }

            })
        })
        .catch(error => console.log(error));


    // Marked
    marked.use({ mangle: false, headerIds: false })
    const sectionsReady = Promise.all(section_names.map(name => {
        return fetch(content_dir + name + '.md')
            .then(response => response.text())
            .then(markdown => {
                const html = marked.parse(markdown);
                document.getElementById(name + '-md').innerHTML = html;
            })
            .catch(error => console.log(error));
    }));

    const mathReady = sectionsReady.then(() => {
        if (window.MathJax && typeof MathJax.typesetPromise === 'function') {
            return MathJax.typesetPromise();
        }
    }).catch(error => console.log(error));

    const renderReady = Promise.all([configReady, sectionsReady, mathReady]);

    const printPage = async () => {
        try {
            await renderReady;
            if (document.fonts && typeof document.fonts.ready?.then === 'function') {
                await document.fonts.ready;
            }
        } catch (error) {
            console.log(error);
        }

        window.print();
    };

    printButtons.forEach(button => {
        button.addEventListener('click', printPage);
    });

}); 
